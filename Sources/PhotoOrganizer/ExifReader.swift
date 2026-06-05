import Foundation
import ImageIO

class ExifReader {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()

    static func resolveDateKey(files: [String]) -> String {
        guard let target = files.sorted(by: {
            ($0 as NSString).lastPathComponent.lowercased() < ($1 as NSString).lastPathComponent.lowercased()
        }).first else {
            return dateFormatter.string(from: Date())
        }

        if let date = readExifDate(from: target) {
            return dateFormatter.string(from: date)
        }

        let fm = FileManager.default
        if let attrs = try? fm.attributesOfItem(atPath: target),
           let date = attrs[.creationDate] as? Date {
            return dateFormatter.string(from: date)
        }

        return dateFormatter.string(from: Date())
    }

    static func readExifDate(from path: String) -> Date? {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else {
            return nil
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
            return nil
        }

        if let dateStr = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String,
           let date = exifDateFormatter.date(from: dateStr) {
            return date
        }

        if let dateStr = exifDict[kCGImagePropertyExifDateTimeDigitized as String] as? String,
           let date = exifDateFormatter.date(from: dateStr) {
            return date
        }

        return nil
    }
}
