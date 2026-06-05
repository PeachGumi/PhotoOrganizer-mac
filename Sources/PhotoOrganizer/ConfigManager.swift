import Foundation

class ConfigManager {
    static let defaultRawExtensions: Set<String> = [
        ".arw", ".cr2", ".cr3", ".nef", ".dng", ".raf", ".rw2", ".orf", ".pef"
    ]

    static func loadConfig(configPath: String? = nil) -> Set<String> {
        let path = configPath ?? getConfigPath()
        guard FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let config = try? JSONDecoder().decode(AppConfigData.self, from: data),
              let extensions = config.rawExtensions, !extensions.isEmpty else {
            return defaultRawExtensions
        }

        let normalized = Set(extensions.compactMap { normalizeExtension($0) })
        return normalized.isEmpty ? defaultRawExtensions : normalized
    }

    static func normalizeExtension(_ ext: String) -> String? {
        let trimmed = ext.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let value = trimmed.hasPrefix(".") ? trimmed : ".\(trimmed)"
        // ドットのみの拡張子（"."や".."）は無効
        guard value.count > 1 else { return nil }
        let withoutDot = String(value.dropFirst())
        guard !withoutDot.isEmpty && !withoutDot.allSatisfy({ $0 == "." }) else { return nil }
        return value.lowercased()
    }

    static func getConfigPath() -> String {
        // 1. ユーザー設定ディレクトリを優先（編集可能）
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let userConfigPath = appSupport.appendingPathComponent("PhotoOrganizer-mac/config.json").path
        if FileManager.default.fileExists(atPath: userConfigPath) {
            return userConfigPath
        }

        // 2. バンドル内のconfig.json（デフォルト）
        if let resourcePath = Bundle.main.resourcePath {
            let bundleConfig = (resourcePath as NSString).appendingPathComponent("config.json")
            if FileManager.default.fileExists(atPath: bundleConfig) {
                return bundleConfig
            }
        }

        // 3. 実行ファイルの場所（フォールバック）
        let execPath = CommandLine.arguments[0]
        let execDir = (execPath as NSString).deletingLastPathComponent
        return (execDir as NSString).appendingPathComponent("config.json")
    }

    static func getUserConfigPath() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("PhotoOrganizer-mac/config.json").path
    }
}
