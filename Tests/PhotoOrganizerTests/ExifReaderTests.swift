import Testing
import Foundation
@testable import PhotoOrganizer

struct ExifReaderTests {
    private func makeTempDir(prefix: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    // MARK: - 基本フォールバックテスト

    @Test func testResolveDateKey_EmptyFiles() {
        let dateKey = ExifReader.resolveDateKey(files: [])
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        #expect(dateKey == today)
    }

    @Test func testResolveDateKey_NoExifFile() throws {
        let tempDir = try makeTempDir(prefix: "ExifReaderTest")
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

    // MARK: - EXIF DateTimeOriginal テスト

    @Test func testResolveDateKey_ExifDateTimeOriginal() throws {
        let tempDir = try makeTempDir(prefix: "ExifDateTimeOriginalTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.jpg").path
        let created = TestImageHelper.createJPEGWithExif(
            at: testFile,
            dateTimeOriginal: "2023:03:15 14:30:00"
        )
        #expect(created)

        let dateKey = ExifReader.resolveDateKey(files: [testFile])
        #expect(dateKey == "2023-03-15")
    }

    @Test func testResolveDateKey_ExifDateTimeOriginal_YearBoundary() throws {
        let tempDir = try makeTempDir(prefix: "ExifYearBoundaryTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let newYear = tempDir.appendingPathComponent("newyear.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: newYear, dateTimeOriginal: "2024:01:01 00:00:00"))
        #expect(ExifReader.resolveDateKey(files: [newYear]) == "2024-01-01")

        let yearEnd = tempDir.appendingPathComponent("yearend.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: yearEnd, dateTimeOriginal: "2023:12:31 23:59:59"))
        #expect(ExifReader.resolveDateKey(files: [yearEnd]) == "2023-12-31")
    }

    @Test func testResolveDateKey_ExifDateTimeOriginal_LegacyYear() throws {
        let tempDir = try makeTempDir(prefix: "ExifLegacyYearTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("old.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: testFile, dateTimeOriginal: "2005:06:15 12:00:00"))
        #expect(ExifReader.resolveDateKey(files: [testFile]) == "2005-06-15")
    }

    // MARK: - EXIF DateTimeDigitized フォールバックテスト

    @Test func testResolveDateKey_ExifDateTimeDigitizedFallback() throws {
        let tempDir = try makeTempDir(prefix: "ExifDateTimeDigitizedTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.jpg").path
        let created = TestImageHelper.createJPEGWithExif(
            at: testFile,
            dateTimeDigitized: "2022:07:20 10:00:00"
        )
        #expect(created)

        let dateKey = ExifReader.resolveDateKey(files: [testFile])
        #expect(dateKey == "2022-07-20")
    }

    @Test func testResolveDateKey_ExifDateTimeOriginalTakesPrecedence() throws {
        let tempDir = try makeTempDir(prefix: "ExifPrecedenceTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.jpg").path
        let created = TestImageHelper.createJPEGWithExif(
            at: testFile,
            dateTimeOriginal: "2023:03:15 14:30:00",
            dateTimeDigitized: "2022:07:20 10:00:00"
        )
        #expect(created)

        let dateKey = ExifReader.resolveDateKey(files: [testFile])
        #expect(dateKey == "2023-03-15")
    }

    // MARK: - 複数ファイルのEXIF解決テスト

    @Test func testResolveDateKey_MultipleFilesFirstHasExif() throws {
        let tempDir = try makeTempDir(prefix: "ExifMultiFirstTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("A_photo.jpg").path
        let fileB = tempDir.appendingPathComponent("B_photo.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: fileA, dateTimeOriginal: "2023:03:15 14:30:00"))
        #expect(TestImageHelper.createJPEGWithExif(at: fileB, dateTimeOriginal: "2024:08:20 10:00:00"))

        let dateKey = ExifReader.resolveDateKey(files: [fileB, fileA])
        #expect(dateKey == "2023-03-15")
    }

    @Test func testResolveDateKey_MultipleFilesFirstNoExifSecondHasExif() throws {
        let tempDir = try makeTempDir(prefix: "ExifMultiMixedTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("A_noexif.jpg")
        let fileB = tempDir.appendingPathComponent("B_exif.jpg").path
        try "dummy".write(to: fileA, atomically: true, encoding: .utf8)
        #expect(TestImageHelper.createJPEGWithExif(at: fileB, dateTimeOriginal: "2024:08:20 10:00:00"))

        let dateKey = ExifReader.resolveDateKey(files: [fileA.path, fileB])
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let attrs = try FileManager.default.attributesOfItem(atPath: fileA.path)
        let creationDate = attrs[.creationDate] as! Date
        let expected = formatter.string(from: creationDate)
        #expect(dateKey == expected)
    }

    @Test func testResolveDateKey_MultipleFilesAllHaveExif() throws {
        let tempDir = try makeTempDir(prefix: "ExifMultiAllTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file1 = tempDir.appendingPathComponent("IMG_001.jpg").path
        let file2 = tempDir.appendingPathComponent("IMG_002.jpg").path
        let file3 = tempDir.appendingPathComponent("IMG_003.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: file1, dateTimeOriginal: "2023:01:10 09:00:00"))
        #expect(TestImageHelper.createJPEGWithExif(at: file2, dateTimeOriginal: "2023:01:11 10:00:00"))
        #expect(TestImageHelper.createJPEGWithExif(at: file3, dateTimeOriginal: "2023:01:12 11:00:00"))

        let dateKey = ExifReader.resolveDateKey(files: [file3, file1, file2])
        #expect(dateKey == "2023-01-10")
    }

    // MARK: - ファイル名ソートテスト

    @Test func testResolveDateKey_SortedByFileName() throws {
        let tempDir = try makeTempDir(prefix: "ExifReaderSortTest")
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

    @Test func testResolveDateKey_SortedCaseInsensitive() throws {
        let tempDir = try makeTempDir(prefix: "ExifSortCaseTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("b_photo.jpg").path
        let fileB = tempDir.appendingPathComponent("A_photo.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: fileA, dateTimeOriginal: "2023:05:01 12:00:00"))
        #expect(TestImageHelper.createJPEGWithExif(at: fileB, dateTimeOriginal: "2024:09:20 08:00:00"))

        let dateKey = ExifReader.resolveDateKey(files: [fileA, fileB])
        #expect(dateKey == "2024-09-20")
    }

    // MARK: - readExifDate 直接テスト

    @Test func testReadExifDate_ValidExif() throws {
        let tempDir = try makeTempDir(prefix: "ReadExifDateTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: testFile, dateTimeOriginal: "2023:03:15 14:30:00"))

        let date = ExifReader.readExifDate(from: testFile)
        #expect(date != nil)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let expected = formatter.date(from: "2023:03:15 14:30:00")
        #expect(date == expected)
    }

    @Test func testReadExifDate_NonImageReturnsNil() throws {
        let tempDir = try makeTempDir(prefix: "ReadExifNonImageTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("test.txt")
        try "not an image".write(to: testFile, atomically: true, encoding: .utf8)

        let date = ExifReader.readExifDate(from: testFile.path)
        #expect(date == nil)
    }

    @Test func testReadExifDate_JpegWithoutExifReturnsNil() throws {
        let tempDir = try makeTempDir(prefix: "ReadExifNoExifTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = tempDir.appendingPathComponent("noexif.jpg").path
        #expect(TestImageHelper.createJPEGWithExif(at: testFile))

        let date = ExifReader.readExifDate(from: testFile)
        #expect(date == nil)
    }

    @Test func testReadExifDate_NonExistentPathReturnsNil() {
        let date = ExifReader.readExifDate(from: "/non/existent/path/\(UUID().uuidString).jpg")
        #expect(date == nil)
    }
}
