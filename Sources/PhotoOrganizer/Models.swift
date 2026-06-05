import Foundation

enum FileProcessStatus {
    case copied
    case skippedUnsupported
    case skippedDuplicate
    case failed
}

struct ProcessResult {
    let raw: Int
    let jpg: Int
    let mp4: Int
    let skipUnsupported: Int
    let skipDuplicate: Int
    let failed: Int
    let basePath: String
    let errors: [String: String]
}

struct MediaError: Error, LocalizedError {
    let message: String
    let file: String?

    var errorDescription: String? {
        if let file = file {
            return "\(file): \(message)"
        }
        return message
    }
}

struct AppConfigData: Codable {
    var rawExtensions: [String]?

    enum CodingKeys: String, CodingKey {
        case rawExtensions = "RawExtensions"
    }
}

struct AppStateData: Codable {
    var destinationPath: String
    var selectedSdPath: String
    var autoStart: Bool
    var startInBackground: Bool
}
