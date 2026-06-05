import Testing
import Foundation
@testable import PhotoOrganizer

struct ExifErrorTests {
    @Test func testCorruptedFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorruptedFileTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let corruptedFile = tempDir.appendingPathComponent("corrupted.jpg")
        try "this is not a valid image file content".write(to: corruptedFile, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [corruptedFile.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: corruptedFile.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }

    @Test func testZeroByteFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZeroByteTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let zeroFile = tempDir.appendingPathComponent("zero.jpg")
        try "".write(to: zeroFile, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [zeroFile.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: zeroFile.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }

    @Test func testNonImageFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NonImageTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let textFile = tempDir.appendingPathComponent("document.txt")
        try "This is a text file, not an image".write(to: textFile, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [textFile.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: textFile.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }

    @Test func testMultipleFilesWithCorrupted() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MultipleCorruptedTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file1 = tempDir.appendingPathComponent("B_corrupted.jpg")
        try "corrupted".write(to: file1, atomically: true, encoding: .utf8)

        let file2 = tempDir.appendingPathComponent("A_valid.jpg")
        try "valid".write(to: file2, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [file1.path, file2.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: file2.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }

    @Test func testFileWithNoReadPermission() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoPermissionTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let noPermFile = tempDir.appendingPathComponent("noperm.jpg")
        try "content".write(to: noPermFile, atomically: true, encoding: .utf8)

        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: noPermFile.path)

        let dateKey = ExifReader.resolveDateKey(files: [noPermFile.path])

        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: noPermFile.path)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        #expect(!dateKey.isEmpty)
        #expect(dateKey.count == 10)
    }
}
