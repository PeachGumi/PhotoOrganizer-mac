import Testing
import Foundation
@testable import PhotoOrganizer

struct ExifErrorTests {
    private func makeTempDir(prefix: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    @Test func testCorruptedFile() throws {
        let tempDir = try makeTempDir(prefix: "CorruptedFileTest")
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
        let tempDir = try makeTempDir(prefix: "ZeroByteTest")
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
        let tempDir = try makeTempDir(prefix: "NonImageTest")
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
        let tempDir = try makeTempDir(prefix: "MultipleCorruptedTest")
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
        let tempDir = try makeTempDir(prefix: "NoPermissionTest")
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

    @Test func testJpegWithoutExifData() throws {
        let tempDir = try makeTempDir(prefix: "JpegNoExifTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("noexif.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: testFile))

        let dateKey = ExifReader.resolveDateKey(files: [testFile])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: testFile)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }

    @Test func testTruncatedJpegFile() throws {
        let tempDir = try makeTempDir(prefix: "TruncatedJpegTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let validFile = tempDir.appendingPathComponent("valid.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: validFile, dateTimeOriginal: "2023:03:15 14:30:00"))

        let validData = try Data(contentsOf: URL(fileURLWithPath: validFile))
        let truncatedData = validData.prefix(validData.count / 2)

        let truncatedFile = tempDir.appendingPathComponent("truncated.jpg")
        try truncatedData.write(to: truncatedFile)

        let dateKey = ExifReader.resolveDateKey(files: [truncatedFile.path])
        #expect(!dateKey.isEmpty)
        #expect(dateKey.count == 10)
    }

    @Test func testFakeImageFileReturnsNil() throws {
        let tempDir = try makeTempDir(prefix: "FakeImageTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeFile = tempDir.appendingPathComponent("fake.jpg")
        try "not real image data".write(to: fakeFile, atomically: true, encoding: .utf8)

        let date = ExifReader.readExifDate(from: fakeFile.path)
        #expect(date == nil)
    }

    @Test func testNonExistentFileReturnsNil() {
        let date = ExifReader.readExifDate(from: "/nonexistent/\(UUID().uuidString)/photo.jpg")
        #expect(date == nil)
    }

    @Test func testDirectoryPathReturnsNil() throws {
        let tempDir = try makeTempDir(prefix: "DirPathTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let date = ExifReader.readExifDate(from: tempDir.path)
        #expect(date == nil)
    }

    @Test func testAllFilesCorruptedReturnsCreationDate() throws {
        let tempDir = try makeTempDir(prefix: "AllCorruptedTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file1 = tempDir.appendingPathComponent("A_bad.jpg")
        let file2 = tempDir.appendingPathComponent("B_bad.jpg")
        try "garbage1".write(to: file1, atomically: true, encoding: .utf8)
        try "garbage2".write(to: file2, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [file1.path, file2.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: file1.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }
}
