import Testing
import Foundation
@testable import PhotoOrganizer

struct IntegrationTests {
    @Test func testEndToEnd_SDCardSimulation() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrationTest_\(UUID().uuidString)")
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
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrationDuplicateTest_\(UUID().uuidString)")
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
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrationFormatsTest_\(UUID().uuidString)")
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

    @Test func testEndToEnd_FolderStructure() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrationFolderTest_\(UUID().uuidString)")
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
}
