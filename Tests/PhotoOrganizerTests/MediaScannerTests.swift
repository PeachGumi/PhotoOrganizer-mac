import Testing
import Foundation
@testable import PhotoOrganizer

struct MediaScannerTests {
    let scanner: MediaScanner

    init() {
        scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
    }

    private func makeTempDir(prefix: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    // MARK: - getMediaKind テスト

    @Test func testGetMediaKind_RAW() {
        #expect(scanner.getMediaKind("/path/to/image.arw") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.ARW") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.cr2") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.nef") == "RAW")
        #expect(scanner.getMediaKind("/path/to/image.dng") == "RAW")
    }

    @Test func testGetMediaKind_AllRawFormats() {
        let rawFormats = [".arw", ".cr2", ".cr3", ".nef", ".dng", ".raf", ".rw2", ".orf", ".pef"]
        for ext in rawFormats {
            #expect(scanner.getMediaKind("/path/to/image\(ext)") == "RAW", "Failed for \(ext)")
        }
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

    @Test func testGetMediaKind_CommonNonMediaFormats() {
        let nonMedia = [".png", ".gif", ".bmp", ".tiff", ".pdf", ".doc", ".xls", ".zip", ".txt"]
        for ext in nonMedia {
            #expect(scanner.getMediaKind("/path/to/file\(ext)") == nil, "Should be nil for \(ext)")
        }
    }

    // MARK: - countByType テスト

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

    @Test func testCountByType_EmptyList() {
        let (raw, jpg, mp4) = scanner.countByType([])
        #expect(raw == 0)
        #expect(jpg == 0)
        #expect(mp4 == 0)
    }

    @Test func testCountByType_OnlyRaw() {
        let files = ["/a.arw", "/b.cr2", "/c.nef"]
        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 3)
        #expect(jpg == 0)
        #expect(mp4 == 0)
    }

    @Test func testCountByType_OnlyJpg() {
        let files = ["/a.jpg", "/b.jpeg"]
        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 0)
        #expect(jpg == 2)
        #expect(mp4 == 0)
    }

    @Test func testCountByType_OnlyMp4() {
        let files = ["/a.mp4", "/b.mov"]
        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 0)
        #expect(jpg == 0)
        #expect(mp4 == 2)
    }

    @Test func testCountByType_NoMediaFiles() {
        let files = ["/a.txt", "/b.pdf", "/c.png"]
        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 0)
        #expect(jpg == 0)
        #expect(mp4 == 0)
    }

    // MARK: - enumerateMediaFiles テスト

    @Test func testEnumerateMediaFiles() throws {
        let tempDir = try makeTempDir(prefix: "MediaScannerTest")
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
        let tempDir = try makeTempDir(prefix: "MediaScannerNestedTest")
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

    @Test func testEnumerateMediaFiles_EmptyDirectory() throws {
        let tempDir = try makeTempDir(prefix: "MediaScannerEmptyTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.isEmpty)
    }

    @Test func testEnumerateMediaFiles_NonExistentDirectory() {
        let files = scanner.enumerateMediaFiles(root: "/nonexistent/\(UUID().uuidString)")
        #expect(files.isEmpty)
    }

    @Test func testEnumerateMediaFiles_HiddenDirectorySkipped() throws {
        let tempDir = try makeTempDir(prefix: "MediaScannerHiddenTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let hiddenDir = tempDir.appendingPathComponent(".hidden")
        try FileManager.default.createDirectory(at: hiddenDir, withIntermediateDirectories: true)
        try "".write(to: hiddenDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let visibleDir = tempDir.appendingPathComponent("visible")
        try FileManager.default.createDirectory(at: visibleDir, withIntermediateDirectories: true)
        try "".write(to: visibleDir.appendingPathComponent("IMG_0002.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0].contains("visible"))
    }

    @Test func testEnumerateMediaFiles_DotFilesSkipped() throws {
        let tempDir = try makeTempDir(prefix: "MediaScannerDotTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "".write(to: tempDir.appendingPathComponent(".DS_Store"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent(".hidden.jpg"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0].hasSuffix("IMG_0001.JPG"))
    }

    @Test func testEnumerateMediaFiles_SdCardStructure() throws {
        let tempDir = try makeTempDir(prefix: "MediaScannerSDTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dir100 = tempDir.appendingPathComponent("DCIM/100CANON")
        let dir101 = tempDir.appendingPathComponent("DCIM/101CANON")
        try FileManager.default.createDirectory(at: dir100, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir101, withIntermediateDirectories: true)

        try "".write(to: dir100.appendingPathComponent("IMG_0001.CR2"), atomically: true, encoding: .utf8)
        try "".write(to: dir100.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "".write(to: dir101.appendingPathComponent("IMG_0002.CR2"), atomically: true, encoding: .utf8)
        try "".write(to: dir101.appendingPathComponent("IMG_0002.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 4)
    }

    @Test func testEnumerateMediaFiles_MixedMediaTypes() throws {
        let tempDir = try makeTempDir(prefix: "MediaScannerMixedTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "".write(to: tempDir.appendingPathComponent("IMG_0001.ARW"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent("VID_0002.MOV"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 4)

        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 1)
        #expect(jpg == 1)
        #expect(mp4 == 2)
    }
}
