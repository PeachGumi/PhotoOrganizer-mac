import Testing
import Foundation
@testable import PhotoOrganizer

struct ScannerErrorTests {
    let scanner: MediaScanner

    init() {
        scanner = MediaScanner(rawExtensions: ConfigManager.defaultRawExtensions)
    }

    @Test func testNonExistentRootDirectory() throws {
        let nonExistentPath = "/non/existent/path/\(UUID().uuidString)"
        let files = scanner.enumerateMediaFiles(root: nonExistentPath)
        #expect(files.isEmpty)
    }

    @Test func testRootIsFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RootIsFileTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let filePath = tempDir.appendingPathComponent("file.txt")
        try "content".write(to: filePath, atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: filePath.path)
        #expect(files.isEmpty)
    }

    @Test func testDirectoryWithNoReadPermission() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoPermDirTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempDir.path)
            try? FileManager.default.removeItem(at: tempDir)
        }

        let subDir = tempDir.appendingPathComponent("noperm")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        try "content".write(to: subDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: subDir.path)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)

        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: subDir.path)

        #expect(files.isEmpty)
    }

    @Test func testSymlinkHandling() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SymlinkTest_\(UUID().uuidString)")
        let realDir = tempDir.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: realDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "content".write(to: realDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let symlinkPath = tempDir.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: symlinkPath, withDestinationURL: realDir)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count >= 1)
    }

    @Test func testHiddenDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HiddenDirTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let hiddenDir = tempDir.appendingPathComponent(".hidden")
        try FileManager.default.createDirectory(at: hiddenDir, withIntermediateDirectories: true)
        try "content".write(to: hiddenDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.isEmpty)
    }

    @Test func testDotFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DotFilesTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "content".write(to: tempDir.appendingPathComponent(".hidden.jpg"), atomically: true, encoding: .utf8)
        try "content".write(to: tempDir.appendingPathComponent(".DS_Store"), atomically: true, encoding: .utf8)
        try "content".write(to: tempDir.appendingPathComponent("visible.jpg"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 1)
        #expect(files[0].hasSuffix("visible.jpg"))
    }

    @Test func testMixedContentDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MixedContentTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "raw".write(to: tempDir.appendingPathComponent("IMG_0001.ARW"), atomically: true, encoding: .utf8)
        try "jpg".write(to: tempDir.appendingPathComponent("IMG_0001.JPG"), atomically: true, encoding: .utf8)
        try "mp4".write(to: tempDir.appendingPathComponent("VID_0001.MP4"), atomically: true, encoding: .utf8)
        try "txt".write(to: tempDir.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
        try "pdf".write(to: tempDir.appendingPathComponent("DOC.pdf"), atomically: true, encoding: .utf8)
        try "png".write(to: tempDir.appendingPathComponent("ICON.png"), atomically: true, encoding: .utf8)
        try "hidden".write(to: tempDir.appendingPathComponent(".hidden.jpg"), atomically: true, encoding: .utf8)

        let files = scanner.enumerateMediaFiles(root: tempDir.path)
        #expect(files.count == 3)

        let (raw, jpg, mp4) = scanner.countByType(files)
        #expect(raw == 1)
        #expect(jpg == 1)
        #expect(mp4 == 1)
    }

    @Test func testCustomRawExtensions() throws {
        let customScanner = MediaScanner(rawExtensions: [".custom", ".raw"])

        #expect(customScanner.getMediaKind("test.custom") == "RAW")
        #expect(customScanner.getMediaKind("test.raw") == "RAW")
        #expect(customScanner.getMediaKind("test.arw") == nil)
    }

    @Test func testEmptyRawExtensions() throws {
        let emptyScanner = MediaScanner(rawExtensions: [])

        #expect(emptyScanner.getMediaKind("test.arw") == nil)
        #expect(emptyScanner.getMediaKind("test.jpg") == "JPG")
        #expect(emptyScanner.getMediaKind("test.mp4") == "MP4")
    }
}
