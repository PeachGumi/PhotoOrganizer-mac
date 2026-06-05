import Testing
import Foundation
@testable import PhotoOrganizer

struct ExifReaderTests {
    @Test func testResolveDateKey_EmptyFiles() {
        let dateKey = ExifReader.resolveDateKey(files: [])
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        #expect(dateKey == today)
    }

    @Test func testResolveDateKey_NoExifFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExifReaderTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.jpg")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [testFile.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: testFile.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }

    @Test func testResolveDateKey_SortedByFileName() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExifReaderSortTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file1 = tempDir.appendingPathComponent("B_file.jpg")
        let file2 = tempDir.appendingPathComponent("A_file.jpg")
        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)

        let dateKey = ExifReader.resolveDateKey(files: [file1.path, file2.path])

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: file2.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)

        #expect(dateKey == expected)
    }
}
