import Testing
import Foundation
@testable import PhotoOrganizer

struct MediaScannerTests {
    let scanner: MediaScanner

    init() {
        scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
    }

    @Test func testGetMediaKind_RAW() {
        #expect(scanner.getMediaKind("/path/to/image.arw") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.ARW") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.cr2") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.nef") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.dng") == "RAW")
    }

    @Test func testGetMediaKind_JPG() {
        #expect(scanner.getMediaKind("/path/to/image.jpg") == "JPG")
        #expect(scanner.getMediaKind("/path/to/image.JPG") == "JPG")
        #expect(scanner.getMediaKind("/path/to/image.jpeg") == "JPG")
        #expect(scanner.getMediaKind("/path/to/image.JPEG") == "JPG")
    }

    @Test func testGetMediaKind_MP4() {
        #expect(scanner.getMediaKind("/path/to/video.mp4") == "MP4")
        #expect(scanner.getMediaKind("/path/to/video.MP4") == "MP4")
        #expect(scanner.getMediaKind("/path/to/video.mov") == "MP4")
        #expect(scanner.getMediaKind("/path/to/video.MOV") == "MP4")
    }

    @Test func testGetMediaKind_Unknown() {
        #expect(scanner.getMediaKind("/path/to/file.txt") == nil)
        #expect(scanner.getMediaKind("/path/to/file.png") == nil)
        #expect(scanner.getMediaKind("/path/to/file") == nil)
    }

    @Test func testCountByType() {
        let files = [
            "/path/to/image1.arw",
            "/path/to/image2.arw",
            "/path/to/image3.jpg",
            "/path/to/video1.mp4",
            "/path/to/video2.mov",
            "/path/to/file.txt"
        ]
        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 2)
        #expect(jpg == 1)
        #expect(mp4 == 2)
    }

    @Test func testEnumerateMediaFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MediaScannerTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dcimDir = tempDir.appendingPathComponent("DCIM")
        try FileManager.default.createDirectory(at: dcimDir, withIntermediateDirectories: true)

        try "".write(to: dcimDir.appendingPathComponent("IMG_0001.ARW"), atomically: true, encoding: .utf8)
        try "".write(to: dcimDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "".write(to: dcimDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "".write(to: dcimDir.appendingPathComponent(".hidden.jpg"), atomically: true, encoding: .utf8)
        try "".write(to: dcimDir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)

        #expect(files.count == 3)
        #expect(files.contains { $0.hasSuffix("IMG_0001.ARW") })
        #expect(files.contains { $0.hasSuffix("IMG_0001.JPG") })
        #expect(files.contains { $0.hasSuffix("VID_0001.MP4") })
        #expect(!files.contains { $0.hasSuffix(".hidden.jpg") })
        #expect(!files.contains { $0.hasSuffix("readme.txt") })
    }

    @Test func testEnumerateMediaFiles_NestedDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MediaScannerNestedTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let subDir1 = tempDir.appendingPathComponent("DCIM/100CANON")
        try FileManager.default.createDirectory(at: subDir1, withIntermediateDirectories: true)

        let subDir2 = tempDir.appendingPathComponent("PRIVATE/M4_ROOT")
        try FileManager.default.createDirectory(at: subDir2, withIntermediateDirectories: true)

        try "".write(to: subDir1.appendingPathComponent("IMG_0001.CR2"), atomically: true, encoding: .utf8)
        try "".write(to: subDir2.appendingPathComponent("IMG_0002.NEF"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)

        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix("IMG_0001.CR2") })
        #expect(files.contains { $0.hasSuffix("IMG_0002.NEF") })
    }
}
