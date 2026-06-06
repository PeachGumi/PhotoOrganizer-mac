import Foundation
import ImageIO
import CoreGraphics

enum TestImageHelper {
    static func createJPEGWithExif(
        at path: String,
        dateTimeOriginal: String? = nil,
        dateTimeDigitized: String? = nil
    ) -> Bool {
        let url = URL(fileURLWithPath: path)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard let image = context.makeImage() else { return false }

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return false }

        var properties: [String: Any] = [:]
        var exifDict: [String: Any] = [:]

        if let dateTimeOriginal = dateTimeOriginal {
            exifDict[kCGImagePropertyExifDateTimeOriginal as String] = dateTimeOriginal
        }
        if let dateTimeDigitized = dateTimeDigitized {
            exifDict[kCGImagePropertyExifDateTimeDigitized as String] = dateTimeDigitized
        }

        if !exifDict.isEmpty {
            properties[kCGImagePropertyExifDictionary as String] = exifDict
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
}
