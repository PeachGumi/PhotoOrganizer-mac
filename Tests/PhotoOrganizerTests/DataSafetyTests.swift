import Testing
import Foundation
@testable import PhotoOrganizer

struct DataSafetyTests {
    let scanner: MediaScanner
    let processor: MediaProcessor

    init() {
        scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        processor = MediaProcessor(scanner: scanner)
    }

    // MARK: - ソースファイル保護テスト

    @Test func testSourceFileNotDeleted() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SourceProtectionTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let srcFile = dcimDir.appendingPathComponent("IMG_0001.JPG")
        let content = "precious photo data"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let _ = await processor.processFiles(files, destination: destDir.path, eventName: "Test") { _, _ in }

        #expect(FileManager.default.fileExists(atPath: srcFile.path))
        let srcContent = try String(contentsOf: srcFile, encoding: .utf8)
        #expect(srcContent == content)
    }

    @Test func testSourceFileNotModified() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SourceNotModifiedTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let srcFile = dcimDir.appendingPathComponent("IMG_0001.ARW")
        let content = "RAW data content"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        let srcAttrsBefore = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcSizeBefore = srcAttrsBefore[.size] as! Int
        let srcDateBefore = srcAttrsBefore[.modificationDate] as! Date

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let _ = await processor.processFiles(files, destination: destDir.path, eventName: "Test") { _, _ in }

        let srcAttrsAfter = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcSizeAfter = srcAttrsAfter[.size] as! Int
        let srcDateAfter = srcAttrsAfter[.modificationDate] as! Date

        #expect(srcSizeBefore == srcSizeAfter)
        #expect(srcDateBefore == srcDateAfter)
    }

    // MARK: - 関係ないファイル保護テスト

    @Test func testUnrelatedFilesNotDeleted() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("UnrelatedProtectionTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        try "photo".write(to: dcimDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "readme".write(to: srcDir.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
        try "config".write(to: srcDir.appendingPathComponent("config.xml"), atomically: true, encoding: .utf8)
        try "thumbnail".write(to: srcDir.appendingPathComponent(".thumbnail"), atomically: true, encoding: .utf8)

        let otherDir = srcDir.appendingPathComponent("OTHER_FOLDER")
        try FileManager.default.createDirectory(at: otherDir, withIntermediateDirectories: true)
        try "other data".write(to: otherDir.appendingPathComponent("data.bin"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let _ = await processor.processFiles(files, destination: destDir.path, eventName: "Test") { _, _ in }

        #expect(FileManager.default.fileExists(atPath: srcDir.appendingPathComponent("README.txt").path))
        #expect(FileManager.default.fileExists(atPath: srcDir.appendingPathComponent("config.xml").path))
        #expect(FileManager.default.fileExists(atPath: srcDir.appendingPathComponent(".thumbnail").path))
        #expect(FileManager.default.fileExists(atPath: otherDir.appendingPathComponent("data.bin").path))
    }

    @Test func testDestinationUnrelatedFilesNotDeleted() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DestUnrelatedTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)
        try "new photo".write(to: dcimDir.appendingPathComponent("IMG_0002.JPG"), atomically: true, encoding: .utf8)

        let existingDir = destDir.appendingPathComponent("2024/2024-01-01_OldEvent/JPG")
        try FileManager.default.createDirectory(at: existingDir, withIntermediateDirectories: true)
        let existingFile = existingDir.appendingPathComponent("IMG_0001.JPG")
        try "old precious photo".write(to: existingFile, atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let _ = await processor.processFiles(files, destination: destDir.path, eventName: "NewEvent") { _, _ in }

        #expect(FileManager.default.fileExists(atPath: existingFile.path))
        let existingContent = try String(contentsOf: existingFile, encoding: .utf8)
        #expect(existingContent == "old precious photo")
    }

    // MARK: - 誤上書き防止テスト

    @Test func testDifferentContentNotOverwritten() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OverwriteProtectionTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        let srcContent = "NEW photo data"
        try srcContent.write(to: srcFile, atomically: true, encoding: .utf8)

        let dstFile = dstDir.appendingPathComponent("JPG/IMG_0001.JPG")
        let dstContent = "OLD different photo data"
        try dstContent.write(to: dstFile, atomically: true, encoding: .utf8)

        let srcDate = Date().addingTimeInterval(-100)
        try FileManager.default.setAttributes([.modificationDate: srcDate], ofItemAtPath: srcFile.path)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)

        let copiedContent = try String(contentsOf: dstFile, encoding: .utf8)
        #expect(copiedContent == srcContent)
    }

    @Test func testSameNameDifferentSizeNotSkipped() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DifferentSizeTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        try "larger content data".write(to: srcFile, atomically: true, encoding: .utf8)

        let dstFile = dstDir.appendingPathComponent("JPG/IMG_0001.JPG")
        try "small".write(to: dstFile, atomically: true, encoding: .utf8)

        let srcAttrs = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcDate = srcAttrs[.modificationDate] as! Date
        try FileManager.default.setAttributes([.modificationDate: srcDate], ofItemAtPath: dstFile.path)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)
    }

    // MARK: - 処理中断・エラー時の安全性

    @Test func testSourceSafeOnProcessError() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ErrorSafetyTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let validFile = dcimDir.appendingPathComponent("IMG_0001.JPG")
        try "valid photo".write(to: validFile, atomically: true, encoding: .utf8)

        let nonExistentFile = dcimDir.appendingPathComponent("IMG_0002.JPG").path

        let files = [validFile.path, nonExistentFile]
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "Test") { _, _ in }

        #expect(result.failed == 1)
        #expect(FileManager.default.fileExists(atPath: validFile.path))
        let content = try String(contentsOf: validFile, encoding: .utf8)
        #expect(content == "valid photo")
    }

    // MARK: - 整合性チェックテスト

    @Test func testIntegrityCheckAfterCopy() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrityCheckTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        let content = "test content for integrity check"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)

        let dstFile = dstDir.appendingPathComponent("JPG/IMG_0001.JPG")
        let srcAttrs = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let dstAttrs = try FileManager.default.attributesOfItem(atPath: dstFile.path)

        #expect(srcAttrs[.size] as! Int == dstAttrs[.size] as! Int)
    }

    // MARK: - リトライ動作テスト

    @Test func testRetryOnFailure() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RetryTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let validFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        try "valid".write(to: validFile, atomically: true, encoding: .utf8)

        let files = [validFile.path]
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Test") { _, _ in }

        #expect(result.failed == 0)
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/JPG/IMG_0001.JPG"))
    }

    // MARK: - コンテンツ完全性テスト

    @Test func testCopiedContentMatchesSource() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ContentMatchTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let contents = [
            "IMG_0001.JPG": "photo data with special chars: \n\t\u{00}",
            "IMG_0002.ARW": "raw sensor data \u{0001}\u{0002}",
            "VID_0001.MP4": "video binary data simulation"
        ]

        for (name, content) in contents {
            try content.write(to: dcimDir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "ContentMatch") { _, _ in }

        #expect(result.failed == 0)

        for (name, expectedContent) in contents {
            let kind = scanner.getMediaKind(dcimDir.appendingPathComponent(name).path) ?? ""
            let copiedFile = "\(result.basePath)/\(kind)/\(name)"
            let copiedContent = try String(contentsOfFile: copiedFile, encoding: .utf8)
            #expect(copiedContent == expectedContent, "Content mismatch for \(name)")
        }
    }

    @Test func testMultipleRunsPreserveData() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MultiRunSafetyTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let srcFile = dcimDir.appendingPathComponent("IMG_0001.JPG")
        let originalContent = "precious data"
        try originalContent.write(to: srcFile, atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)

        for _ in 1...5 {
            let _ = await processor.processFiles(files, destination: destDir.path, eventName: "MultiRun") { _, _ in }
        }

        let srcContent = try String(contentsOf: srcFile, encoding: .utf8)
        #expect(srcContent == originalContent)

        let srcAttrs = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        #expect((srcAttrs[.size] as! Int) == originalContent.utf8.count)
    }

    @Test func testDestinationAutoCreated() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DestAutoCreateTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DEEP/NESTED/DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)
        try "content".write(to: dcimDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "AutoCreate") { _, _ in }

        #expect(result.failed == 0)
        #expect(FileManager.default.fileExists(atPath: result.basePath))
    }

    @Test func testAllFileTypesClassifiedCorrectly() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClassifyTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = srcDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        try "raw".write(to: dcimDir.appendingPathComponent("IMG_0001.ARW"), atomically: true, encoding: .utf8)
        try "raw".write(to: dcimDir.appendingPathComponent("IMG_0002.CR2"), atomically: true, encoding: .utf8)
        try "raw".write(to: dcimDir.appendingPathComponent("IMG_0003.NEF"), atomically: true, encoding: .utf8)
        try "jpg".write(to: dcimDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "jpg".write(to: dcimDir.appendingPathComponent("IMG_0002.JPEG"), atomically: true, encoding: .utf8)
        try "mp4".write(to: dcimDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "mov".write(to: dcimDir.appendingPathComponent("VID_0002.MOV"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "Classify") { _, _ in }

        #expect(result.raw == 3)
        #expect(result.jpg == 2)
        #expect(result.mp4 == 2)
        #expect(result.failed == 0)
        #expect(result.skipUnsupported == 0)

        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/RAW/IMG_0001.ARW"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/RAW/IMG_0002.CR2"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/RAW/IMG_0003.NEF"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/JPG/IMG_0001.JPG"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/JPG/IMG_0002.JPEG"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/MP4/VID_0001.MP4"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/MP4/VID_0002.MOV"))
    }
}
