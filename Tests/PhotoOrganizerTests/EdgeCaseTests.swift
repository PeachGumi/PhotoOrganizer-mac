import Testing
import Foundation
@testable import PhotoOrganizer

struct EdgeCaseTests {
    let scanner: MediaScanner
    let processor: MediaProcessor

    init() {
        scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        processor = MediaProcessor(scanner: scanner)
    }

    // MARK: - 存在しないファイル・パス

    @Test func testNonExistentSourceFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NonExistentTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let nonExistentFile = tempDir.appendingPathComponent("non_existent.jpg").path

        var errors: [String: String] = [:]
        let status = processor.processOneFile(nonExistentFile, basePath: tempDir.path, errors: &errors)

        #expect(status == .failed)
        #expect(!errors.isEmpty)
    }

    @Test func testNonExistentDestinationPath() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NonExistentDestTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "test".write(to: srcDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let nonExistentDest = "/non/existent/path/\(UUID().uuidString)"

        let result = await processor.processFiles(files, destination: nonExistentDest, eventName: "Test") { _, _ in }

        #expect(result.failed > 0 || result.basePath.hasPrefix(nonExistentDest))
    }

    // MARK: - 不正なファイル名

    @Test func testLongFileName() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LongFileNameTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let longName = String(repeating: "A", count: 200) + ".JPG"
        try "content".write(to: srcDir.appendingPathComponent(longName), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Test") { _, _ in }

        #expect(result.jpg == 1)
        #expect(result.failed == 0)
    }

    @Test func testSpecialCharactersInFileName() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpecialCharsTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let specialNames = [
            "IMG (1).JPG",
            "IMG-2024-01-01.JPG",
            "IMG_写真.JPG",
            "IMG.2024.JPG"
        ]

        for name in specialNames {
            try "content".write(to: srcDir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Test") { _, _ in }

        #expect(result.jpg == specialNames.count)
    }

    // MARK: - 空のファイル・極端なサイズ

    @Test func testEmptyFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyFileTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "".write(to: srcDir.appendingPathComponent("EMPTY.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Test") { _, _ in }

        #expect(result.jpg == 1)
        #expect(result.failed == 0)
    }

    @Test func testLargeFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LargeFileTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let largeContent = String(repeating: "X", count: 1024 * 1024)
        try largeContent.write(to: srcDir.appendingPathComponent("LARGE.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Test") { _, _ in }

        #expect(result.jpg == 1)
        #expect(result.failed == 0)
    }

    // MARK: - イベント名の異常系

    @Test func testEmptyEventName() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyEventTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "content".write(to: srcDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "") { _, _ in }

        #expect(result.basePath.contains("_"))
    }

    @Test func testSpecialCharactersInEventName() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpecialEventTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "content".write(to: srcDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: srcDir.path)
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Event/With:Special*Chars") { _, _ in }

        #expect(!result.basePath.contains("/With:"))
        #expect(!result.basePath.contains(":Special"))
    }

    // MARK: - 重複ファイルの異常系

    @Test func testSameNameDifferentContent() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SameNameDiffContentTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        try "SOURCE CONTENT".write(to: srcFile, atomically: true, encoding: .utf8)

        let dstFile = dstDir.appendingPathComponent("JPG/IMG_0001.JPG")
        try "DESTINATION CONTENT".write(to: dstFile, atomically: true, encoding: .utf8)

        let oldDate = Date().addingTimeInterval(-86400)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: dstFile.path)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)

        let copiedContent = try String(contentsOf: dstFile, encoding: .utf8)
        #expect(copiedContent == "SOURCE CONTENT")
    }

    @Test func testSameSizeDifferentContent() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SameSizeDiffContentTest_\(UUID().uuidString)")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        try "AAAAAAAAAA".write(to: srcFile, atomically: true, encoding: .utf8)

        let dstFile = dstDir.appendingPathComponent("JPG/IMG_0001.JPG")
        try "BBBBBBBBBB".write(to: dstFile, atomically: true, encoding: .utf8)

        let srcAttrs = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcDate = srcAttrs[.modificationDate] as! Date
        try FileManager.default.setAttributes([.modificationDate: srcDate], ofItemAtPath: dstFile.path)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .skippedDuplicate)
    }

    // MARK: - ディレクトリ関連

    @Test func testEmptyDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyDirTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.isEmpty)
    }

    @Test func testDeeplyNestedDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeepNestedTest_\(UUID().uuidString)")
        let deepDir = tempDir.appendingPathComponent("a/b/c/d/e/f/g/h/i/j")
        try FileManager.default.createDirectory(at: deepDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "content".write(to: deepDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 1)
    }

    // MARK: - 拡張子の異常系

    @Test func testCaseInsensitiveExtensions() throws {
        #expect(scanner.getMediaKind("test.JPG") == "JPG")
        #expect(scanner.getMediaKind("test.Jpg") == "JPG")
        #expect(scanner.getMediaKind("test.jPg") == "JPG")
        #expect(scanner.getMediaKind("test.ARW") == "RAW")
        #expect(scanner.getMediaKind("test.Arw") == "RAW")
        #expect(scanner.getMediaKind("test.MP4") == "MP4")
        #expect(scanner.getMediaKind("test.Mp4") == "MP4")
    }

    @Test func testDoubleExtensions() throws {
        #expect(scanner.getMediaKind("test.backup.jpg") == "JPG")
        #expect(scanner.getMediaKind("test.copy.arw") == "RAW")
    }

    @Test func testNoExtension() throws {
        #expect(scanner.getMediaKind("IMG_0001") == nil)
        #expect(scanner.getMediaKind("noextension") == nil)
    }
}
