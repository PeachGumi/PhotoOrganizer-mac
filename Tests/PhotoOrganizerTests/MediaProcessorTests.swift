import Testing
import Foundation
@testable import PhotoOrganizer

struct MediaProcessorTests {
    let scanner: MediaScanner
    let processor: MediaProcessor

    init() {
        scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
        processor = MediaProcessor(scanner: scanner)
    }

    private func makeTempDir(prefix: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    @Test func testSanitizeName() {
        #expect(processor.sanitizeName("normal_name") == "normal_name")
        #expect(processor.sanitizeName("name/with/slash") == "name_with_slash")
        #expect(processor.sanitizeName("name\\with\\backslash") == "name_with_backslash")
        #expect(processor.sanitizeName("name:with:colon") == "name_with_colon")
        #expect(processor.sanitizeName("name*with*asterisk") == "name_with_asterisk")
        #expect(processor.sanitizeName("name?with?question") == "name_with_question")
        #expect(processor.sanitizeName("name\"with\"quote") == "name_with_quote")
        #expect(processor.sanitizeName("name<with>bracket") == "name_with_bracket")
        #expect(processor.sanitizeName("name|with|pipe") == "name_with_pipe")
    }

    @Test func testSanitizeName_EmptyString() {
        #expect(processor.sanitizeName("") == "")
    }

    @Test func testSanitizeName_AllInvalidChars() {
        let result = processor.sanitizeName("/\\:*?\"<>|")
        #expect(!result.contains("/"))
        #expect(!result.contains("\\"))
        #expect(!result.contains(":"))
        #expect(!result.contains("*"))
        #expect(!result.contains("?"))
        #expect(!result.contains("\""))
        #expect(!result.contains("<"))
        #expect(!result.contains(">"))
        #expect(!result.contains("|"))
    }

    @Test func testSanitizeName_JapaneseCharacters() {
        #expect(processor.sanitizeName("旅行_2024") == "旅行_2024")
        #expect(processor.sanitizeName("写真/夏") == "写真_夏")
    }

    @Test func testIsSameByTimeAndSize() {
        let now = Date()
        let sameSize = 1000
        let diffSize = 2000

        #expect(processor.isSameByTimeAndSize(srcSize: sameSize, srcDate: now, dstSize: sameSize, dstDate: now) == true)
        #expect(processor.isSameByTimeAndSize(srcSize: sameSize, srcDate: now, dstSize: diffSize, dstDate: now) == false)
        #expect(processor.isSameByTimeAndSize(srcSize: sameSize, srcDate: now, dstSize: sameSize, dstDate: now.addingTimeInterval(1)) == true)
        #expect(processor.isSameByTimeAndSize(srcSize: sameSize, srcDate: now, dstSize: sameSize, dstDate: now.addingTimeInterval(2)) == true)
        #expect(processor.isSameByTimeAndSize(srcSize: sameSize, srcDate: now, dstSize: sameSize, dstDate: now.addingTimeInterval(3)) == false)
    }

    @Test func testProcessOneFile_Copied() throws {
        let tempDir = try makeTempDir(prefix: "ProcessOneFileTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.jpg")
        let content = "test image content"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)
        #expect(errors.isEmpty)

        let dstFile = dstDir.appendingPathComponent("JPG/test.jpg")
        #expect(FileManager.default.fileExists(atPath: dstFile.path))

        let copiedContent = try String(contentsOf: dstFile, encoding: .utf8)
        #expect(copiedContent == content)
    }

    @Test func testProcessOneFile_RawFile() throws {
        let tempDir = try makeTempDir(prefix: "ProcessRawFileTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("RAW"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.arw")
        try "raw data".write(to: srcFile, atomically: true, encoding: .utf8)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)
        #expect(FileManager.default.fileExists(atPath: dstDir.appendingPathComponent("RAW/test.arw").path))
    }

    @Test func testProcessOneFile_Mp4File() throws {
        let tempDir = try makeTempDir(prefix: "ProcessMp4FileTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("MP4"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.mp4")
        try "video data".write(to: srcFile, atomically: true, encoding: .utf8)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)
        #expect(FileManager.default.fileExists(atPath: dstDir.appendingPathComponent("MP4/test.mp4").path))
    }

    @Test func testProcessOneFile_SkippedDuplicate() throws {
        let tempDir = try makeTempDir(prefix: "ProcessDuplicateTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.jpg")
        let content = "test image content"
        try content.write(to: srcFile, atomically: true, encoding: .utf8)

        let dstFile = dstDir.appendingPathComponent("JPG/test.jpg")
        try FileManager.default.createDirectory(at: dstFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: dstFile, atomically: true, encoding: .utf8)

        let srcAttrs = try FileManager.default.attributesOfItem(atPath: srcFile.path)
        let srcDate = srcAttrs[.modificationDate] as! Date
        try FileManager.default.setAttributes([.modificationDate: srcDate], ofItemAtPath: dstFile.path)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .skippedDuplicate)
        #expect(errors.isEmpty)
    }

    @Test func testProcessOneFile_SkippedUnsupported() throws {
        let tempDir = try makeTempDir(prefix: "ProcessUnsupportedTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.txt")
        try "test".write(to: srcFile, atomically: true, encoding: .utf8)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .skippedUnsupported)
    }

    @Test func testProcessFiles() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessFilesTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "".write(to: srcDir.appendingPathComponent("IMG_0001.ARW"), atomically: true, encoding: .utf8)
        try "".write(to: srcDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "".write(to: srcDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "".write(to: srcDir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

        let files = [
            srcDir.appendingPathComponent("IMG_0001.ARW").path,
            srcDir.appendingPathComponent("IMG_0001.JPG").path,
            srcDir.appendingPathComponent("VID_0001.MP4").path,
            srcDir.appendingPathComponent("readme.txt").path
        ]

        var progressCalls: [(Int, Int)] = []
        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "TestEvent") { processed, total in
            progressCalls.append((processed, total))
        }

        #expect(result.raw == 1)
        #expect(result.jpg == 1)
        #expect(result.mp4 == 1)
        #expect(result.skipUnsupported == 1)
        #expect(result.skipDuplicate == 0)
        #expect(result.failed == 0)
        #expect(progressCalls.count == 4)
        #expect(progressCalls.last?.0 == 4)
        #expect(progressCalls.last?.1 == 4)

        #expect(result.basePath.contains("TestEvent"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/RAW/IMG_0001.ARW"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/JPG/IMG_0001.JPG"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/MP4/VID_0001.MP4"))
    }

    @Test func testProcessFiles_EmptyFileList() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessEmptyTest")
        let dstDir = tempDir.appendingPathComponent("dst")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let result = await processor.processFiles([], destination: dstDir.path, eventName: "EmptyTest") { _, _ in }

        #expect(result.raw == 0)
        #expect(result.jpg == 0)
        #expect(result.mp4 == 0)
        #expect(result.skipUnsupported == 0)
        #expect(result.skipDuplicate == 0)
        #expect(result.failed == 0)
        #expect(result.errors.isEmpty)
    }

    @Test func testProcessFiles_OnlyRaw() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessOnlyRawTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "raw1".write(to: srcDir.appendingPathComponent("IMG_0001.ARW"), atomically: true, encoding: .utf8)
        try "raw2".write(to: srcDir.appendingPathComponent("IMG_0002.CR2"), atomically: true, encoding: .utf8)

        let files = [
            srcDir.appendingPathComponent("IMG_0001.ARW").path,
            srcDir.appendingPathComponent("IMG_0002.CR2").path
        ]

        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "RawOnly") { _, _ in }

        #expect(result.raw == 2)
        #expect(result.jpg == 0)
        #expect(result.mp4 == 0)
        #expect(result.failed == 0)
    }

    @Test func testProcessFiles_OnlyJpg() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessOnlyJpgTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "jpg1".write(to: srcDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "jpg2".write(to: srcDir.appendingPathComponent("IMG_0002.JPEG"), atomically: true, encoding: .utf8)

        let files = [
            srcDir.appendingPathComponent("IMG_0001.JPG").path,
            srcDir.appendingPathComponent("IMG_0002.JPEG").path
        ]

        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "JpgOnly") { _, _ in }

        #expect(result.raw == 0)
        #expect(result.jpg == 2)
        #expect(result.mp4 == 0)
        #expect(result.failed == 0)
    }

    @Test func testProcessFiles_OnlyMp4() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessOnlyMp4Test")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "mp4".write(to: srcDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "mov".write(to: srcDir.appendingPathComponent("VID_0002.MOV"), atomically: true, encoding: .utf8)

        let files = [
            srcDir.appendingPathComponent("VID_0001.MP4").path,
            srcDir.appendingPathComponent("VID_0002.MOV").path
        ]

        let result = await processor.processFiles(files, destination: dstDir.path, eventName: "Mp4Only") { _, _ in }

        #expect(result.raw == 0)
        #expect(result.jpg == 0)
        #expect(result.mp4 == 2)
        #expect(result.failed == 0)
    }

    @Test func testProcessFiles_ProgressCallback() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessProgressTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "a".write(to: srcDir.appendingPathComponent("A_0001.JPG"), atomically: true, encoding: .utf8)
        try "b".write(to: srcDir.appendingPathComponent("B_0002.JPG"), atomically: true, encoding: .utf8)
        try "c".write(to: srcDir.appendingPathComponent("C_0003.JPG"), atomically: true, encoding: .utf8)

        let files = [
            srcDir.appendingPathComponent("A_0001.JPG").path,
            srcDir.appendingPathComponent("B_0002.JPG").path,
            srcDir.appendingPathComponent("C_0003.JPG").path
        ]

        var progressCalls: [(Int, Int)] = []
        let _ = await processor.processFiles(files, destination: dstDir.path, eventName: "Progress") { processed, total in
            progressCalls.append((processed, total))
        }

        #expect(progressCalls.count == 3)
        #expect(progressCalls.last?.1 == 3)
        #expect(progressCalls.allSatisfy { $0.1 == 3 })
        #expect(progressCalls.allSatisfy { $0.0 > 0 })
    }

    @Test func testProcessFiles_FolderStructureFromExif() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessExifFolderTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let jpgFile = srcDir.appendingPathComponent("IMG_0001.JPG").path
        #expect(TestImageHelper.createJPEGWithExif(at: jpgFile, dateTimeOriginal: "2023:03:15 14:30:00"))

        let result = await processor.processFiles([jpgFile], destination: dstDir.path, eventName: "ExifFolder") { _, _ in }

        #expect(result.basePath.contains("/2023/"))
        #expect(result.basePath.contains("2023-03-15_ExifFolder"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/RAW"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/JPG"))
        #expect(FileManager.default.fileExists(atPath: "\(result.basePath)/MP4"))
    }

    @Test func testProcessFiles_NonExistentFileFails() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessNonExistentTest")
        let dstDir = tempDir.appendingPathComponent("dst")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let nonExistent = tempDir.appendingPathComponent("nonexistent.jpg").path
        let result = await processor.processFiles([nonExistent], destination: dstDir.path, eventName: "Fail") { _, _ in }

        #expect(result.failed == 1)
        #expect(!result.errors.isEmpty)
    }

    @Test func testProcessFiles_MixedValidAndInvalid() async throws {
        let tempDir = try makeTempDir(prefix: "ProcessMixedTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let validFile = srcDir.appendingPathComponent("IMG_0001.JPG")
        try "valid".write(to: validFile, atomically: true, encoding: .utf8)

        let invalidFile = tempDir.appendingPathComponent("IMG_0002.JPG").path

        let result = await processor.processFiles(
            [validFile.path, invalidFile],
            destination: dstDir.path,
            eventName: "Mixed"
        ) { _, _ in }

        #expect(result.failed >= 1)
        #expect(!result.errors.isEmpty)
        #expect(FileManager.default.fileExists(atPath: validFile.path))
    }

    @Test func testProcessOneFile_ContentPreserved() throws {
        let tempDir = try makeTempDir(prefix: "ContentPreservedTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.jpg")
        let originalContent = "precious photo data with special chars: \n\t\u{00}\u{01}\u{02}"
        try originalContent.write(to: srcFile, atomically: true, encoding: .utf8)

        var errors: [String: String] = [:]
        let status = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        #expect(status == .copied)

        let dstFile = dstDir.appendingPathComponent("JPG/test.jpg")
        let copiedContent = try String(contentsOf: dstFile, encoding: .utf8)
        #expect(copiedContent == originalContent)
    }

    @Test func testProcessOneFile_ModificationDatePreserved() throws {
        let tempDir = try makeTempDir(prefix: "DatePreservedTest")
        let srcDir = tempDir.appendingPathComponent("src")
        let dstDir = tempDir.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dstDir.appendingPathComponent("JPG"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let srcFile = srcDir.appendingPathComponent("test.jpg")
        try "content".write(to: srcFile, atomically: true, encoding: .utf8)

        let oldDate = Date(timeIntervalSince1970: 1609459200)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: srcFile.path)

        var errors: [String: String] = [:]
        let _ = processor.processOneFile(srcFile.path, basePath: dstDir.path, errors: &errors)

        let dstFile = dstDir.appendingPathComponent("JPG/test.jpg")
        let dstAttrs = try FileManager.default.attributesOfItem(atPath: dstFile.path)
        let dstDate = dstAttrs[.modificationDate] as! Date

        #expect(abs(dstDate.timeIntervalSince(oldDate)) < 1.0)
    }
}
