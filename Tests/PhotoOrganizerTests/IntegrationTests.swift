import Testing
import Foundation
@testable import PhotoOrganizer

struct IntegrationTests {
    private func makeTempDir(prefix: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    // MARK: - 基本End-to-Endテスト

    @Test func testEndToEnd_SDCardSimulation() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM/100CANON")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let rawContent = "RAW image data content"
        let jpgContent = "JPG image data content"
        let mp4Content = "MP4 video data content"

        try rawContent.write(to: dcimDir.appendingPathComponent("IMG_0001.CR2"), atomically: true, encoding: .utf8)
        try jpgContent.write(to: dcimDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try mp4Content.write(to: dcimDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "readme".write(to: sdDir.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        #expect(files.count == 3)

        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 1)
        #expect(jpg == 1)
        #expect(mp4 == 1)

        let result = await processor.processFiles(files, destination: destDir.path, eventName: "TestEvent") { _, _ in }

        #expect(result.raw == 1)
        #expect(result.jpg == 1)
        #expect(result.mp4 == 1)
        #expect(result.skipUnsupported == 0)
        #expect(result.skipDuplicate == 0)
        #expect(result.failed == 0)

        #expect(result.basePath.contains(destDir.path))
        #expect(result.basePath.contains("TestEvent"))

        let rawFile = "\(result.basePath)/RAW/IMG_0001.CR2"
        let jpgFile = "\(result.basePath)/JPG/IMG_0001.JPG"
        let mp4File = "\(result.basePath)/MP4/VID_0001.MP4"

        #expect(FileManager.default.fileExists(atPath: rawFile))
        #expect(FileManager.default.fileExists(atPath: jpgFile))
        #expect(FileManager.default.fileExists(atPath: mp4File))

        let copiedRaw = try String(contentsOfFile: rawFile, encoding: .utf8)
        let copiedJpg = try String(contentsOfFile: jpgFile, encoding: .utf8)
        let copiedMp4 = try String(contentsOfFile: mp4File, encoding: .utf8)

        #expect(copiedRaw == rawContent)
        #expect(copiedJpg == jpgContent)
        #expect(copiedMp4 == mp4Content)
    }

    @Test func testEndToEnd_DuplicateDetection() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationDuplicateTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let content = "test image content"
        let srcFile = dcimDir.appendingPathComponent("IMG_0001.JPG")
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)

        let result1 = await processor.processFiles(files, destination: destDir.path, eventName: "Event1") { _, _ in }
        #expect(result1.skipDuplicate == 0)

        let result2 = await processor.processFiles(files, destination: destDir.path, eventName: "Event1") { _, _ in }
        #expect(result2.skipDuplicate == 1)
    }

    @Test func testEndToEnd_MultipleFormats() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationFormatsTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let rawFormats = [".arw", ".cr2", ".cr3", ".nef", ".dng", ".raf", ".rw2", ".orf", ".pef"]
        for format in rawFormats {
            try "raw".write(to: dcimDir.appendingPathComponent("IMG\(format)"), atomically: true, encoding: .utf8)
        }
        try "jpg".write(to: dcimDir.appendingPathComponent("IMG.jpg"), atomically: true, encoding: .utf8)
        try "jpeg".write(to: dcimDir.appendingPathComponent("IMG.jpeg"), atomically: true, encoding: .utf8)
        try "mp4".write(to: dcimDir.appendingPathComponent("VID.mp4"), atomically: true, encoding: .utf8)
        try "mov".write(to: dcimDir.appendingPathComponent("VID.mov"), atomically: true, encoding: .utf8)

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "FormatTest") { _, _ in }

        #expect(result.raw == 9)
        #expect(result.jpg == 2)
        #expect(result.mp4 == 2)
        #expect(result.failed == 0)
    }

    // MARK: - EXIF日付に基づくフォルダ構造テスト

    @Test func testEndToEnd_FolderStructureFromExif() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationExifFolderTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let jpgFile = dcimDir.appendingPathComponent("IMG_0001.JPG").path
        let created = TestImageHelper.createJPEGWithExif(
            at: jpgFile,
            dateTimeOriginal: "2023:03:15 14:30:00"
        )
        #expect(created)

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "ExifTest") { _, _ in }

        let basePath = result.basePath
        #expect(basePath.contains("/2023/"))
        #expect(basePath.contains("2023-03-15_ExifTest"))
        #expect(FileManager.default.fileExists(atPath: "\(basePath)/RAW"))
        #expect(FileManager.default.fileExists(atPath: "\(basePath)/JPG"))
        #expect(FileManager.default.fileExists(atPath: "\(basePath)/MP4"))
    }

    @Test func testEndToEnd_FolderStructureFromExifDigitized() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationExifDigitizedTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let jpgFile = dcimDir.appendingPathComponent("IMG_0001.JPG").path
        #expect(TestImageHelper.createJPEGWithExif(at: jpgFile, dateTimeDigitized: "2022:07:20 10:00:00"))

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "DigitizedTest") { _, _ in }

        #expect(result.basePath.contains("/2022/"))
        #expect(result.basePath.contains("2022-07-20_DigitizedTest"))
    }

    @Test func testEndToEnd_MultipleEventsDifferentExifDates() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationMultiEventTest")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let sdDir1 = tempDir.appendingPathComponent("SD1")
        try FileManager.default.createDirectory(at: sdDir1, withIntermediateDirectories: true)
        let jpgFile1 = sdDir1.appendingPathComponent("IMG_0001.JPG").path
        #expect(TestImageHelper.createJPEGWithExif(at: jpgFile1, dateTimeOriginal: "2023:03:15 14:30:00"))

        let files1 = scanner.enumerateMediaFiles(root: sdDir1.path)
        let result1 = await processor.processFiles(files1, destination: destDir.path, eventName: "Event1") { _, _ in }

        let sdDir2 = tempDir.appendingPathComponent("SD2")
        try FileManager.default.createDirectory(at: sdDir2, withIntermediateDirectories: true)
        let jpgFile2 = sdDir2.appendingPathComponent("IMG_0002.JPG").path
        #expect(TestImageHelper.createJPEGWithExif(at: jpgFile2, dateTimeOriginal: "2024:08:20 10:00:00"))

        let files2 = scanner.enumerateMediaFiles(root: sdDir2.path)
        let result2 = await processor.processFiles(files2, destination: destDir.path, eventName: "Event2") { _, _ in }

        #expect(result1.basePath.contains("2023-03-15_Event1"))
        #expect(result2.basePath.contains("2024-08-20_Event2"))
        #expect(result1.basePath != result2.basePath)

        #expect(FileManager.default.fileExists(atPath: "\(result1.basePath)/JPG/IMG_0001.JPG"))
        #expect(FileManager.default.fileExists(atPath: "\(result2.basePath)/JPG/IMG_0002.JPG"))
    }

    @Test func testEndToEnd_FolderStructure() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationFolderTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)
        try "test".write(to: dcimDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "FolderTest") { _, _ in }

        let basePath = result.basePath
        let pathComponents = basePath.components(separatedBy: "/")

        #expect(pathComponents.contains("DESTINATION"))
        #expect(pathComponents.contains(where: { $0.contains("FolderTest") }))
        #expect(pathComponents.contains(where: { $0.hasPrefix("20") }))

        #expect(FileManager.default.fileExists(atPath: "\(basePath)/RAW"))
        #expect(FileManager.default.fileExists(atPath: "\(basePath)/JPG"))
        #expect(FileManager.default.fileExists(atPath: "\(basePath)/MP4"))
    }

    // MARK: - データ完全性テスト

    @Test func testEndToEnd_ContentPreservedAfterProcess() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationContentTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let originalContent = "precious photo data \n\t with special chars"
        let srcFile = dcimDir.appendingPathComponent("IMG_0001.JPG")
        try originalContent.write(to: srcFile, atomically: true, encoding: .utf8)

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        let result = await processor.processFiles(files, destination: destDir.path, eventName: "ContentTest") { _, _ in }

        let copiedFile = "\(result.basePath)/JPG/IMG_0001.JPG"
        let copiedContent = try String(contentsOfFile: copiedFile, encoding: .utf8)
        #expect(copiedContent == originalContent)
    }

    @Test func testEndToEnd_SourceFilesUnchanged() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationSourceTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = sdDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        let srcFile = dcimDir.appendingPathComponent("IMG_0001.JPG")
        let content = "source content"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        let srcAttrsBefore = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcSizeBefore = srcAttrsBefore[.size] as! Int
        let srcDateBefore = srcAttrsBefore[.modificationDate] as! Date

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        let _ = await processor.processFiles(files, destination: destDir.path, eventName: "SourceTest") { _, _ in }

        let srcAttrsAfter = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcSizeAfter = srcAttrsAfter[.size] as! Int
        let srcDateAfter = srcAttrsAfter[.modificationDate] as! Date

        #expect(srcSizeBefore == srcSizeAfter)
        #expect(srcDateBefore == srcDateAfter)
        #expect(FileManager.default.fileExists(atPath: srcFile.path))
    }

    @Test func testEndToEnd_MultipleBatches() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationMultiBatchTest")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        for batchIndex in 1...3 {
            let sdDir = tempDir.appendingPathComponent("SD_\(batchIndex)")
            try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)

            let dcimDir = sdDir.appendingPathComponent("DCIM")
            try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

            for fileIndex in 1...2 {
                try "content_\(batchIndex)_\(fileIndex)".write(
                    to: dcimDir.appendingPathComponent("IMG_\(batchIndex)\(fileIndex).JPG"),
                    atomically: true,
                    encoding: .utf8
                )
            }

            let files = scanner.enumerateMediaFiles(root: sdDir.path)
            let result = await processor.processFiles(files, destination: destDir.path, eventName: "Batch\(batchIndex)") { _, _ in }

            #expect(result.jpg == 2)
            #expect(result.failed == 0)
        }
    }

    @Test func testEndToEnd_EmptySDCard() async throws {
        let tempDir = try makeTempDir(prefix: "IntegrationEmptySDTest")
        let sdDir = tempDir.appendingPathComponent("SD_CARD")
        let destDir = tempDir.appendingPathComponent("DESTINATION")
        try FileManager.default.createDirectory(at: sdDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        let processor = MediaProcessor(scanner: scanner)

        let files = scanner.enumerateMediaFiles(root: sdDir.path)
        #expect(files.isEmpty)

        let result = await processor.processFiles(files, destination: destDir.path, eventName: "EmptyTest") { _, _ in }
        #expect(result.raw == 0)
        #expect(result.jpg == 0)
        #expect(result.mp4 == 0)
        #expect(result.failed == 0)
    }
}
