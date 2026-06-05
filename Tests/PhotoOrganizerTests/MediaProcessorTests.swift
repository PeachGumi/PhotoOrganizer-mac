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
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProcessOneFileTest_\(UUID().uuidString)")
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

    @Test func testProcessOneFile_SkippedDuplicate() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProcessDuplicateTest_\(UUID().uuidString)")
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
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProcessUnsupportedTest_\(UUID().uuidString)")
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
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProcessFilesTest_\(UUID().uuidString)")
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
}
