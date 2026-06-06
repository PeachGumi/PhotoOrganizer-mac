import Testing
import Foundation
@testable import PhotoOrganizer

struct ConfigManagerTests {
    private func makeTempDir(prefix: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    @Test func testNormalizeExtension() {
        #expect(ConfigManager.normalizeExtension(".arw") == ".arw")
        #expect(ConfigManager.normalizeExtension("arw") == ".arw")
        #expect(ConfigManager.normalizeExtension(".ARW") == ".arw")
        #expect(ConfigManager.normalizeExtension("ARW") == ".arw")
        #expect(ConfigManager.normalizeExtension("  .arw  ") == ".arw")
        #expect(ConfigManager.normalizeExtension("  arw  ") == ".arw")
        #expect(ConfigManager.normalizeExtension("") == nil)
        #expect(ConfigManager.normalizeExtension("   ") == nil)
    }

    @Test func testNormalizeExtension_DotOnly() {
        #expect(ConfigManager.normalizeExtension(".") == nil)
        #expect(ConfigManager.normalizeExtension("..") == nil)
        #expect(ConfigManager.normalizeExtension("...") == nil)
    }

    @Test func testNormalizeExtension_WhitespaceOnly() {
        #expect(ConfigManager.normalizeExtension(" ") == nil)
        #expect(ConfigManager.normalizeExtension("\t") == nil)
        #expect(ConfigManager.normalizeExtension("  .  ") == nil)
    }

    @Test func testDefaultRawExtensions() {
        let defaults = ConfigManager.defaultRawExtensions
        #expect(defaults.contains(".arw"))
        #expect(defaults.contains(".cr2"))
        #expect(defaults.contains(".cr3"))
        #expect(defaults.contains(".nef"))
        #expect(defaults.contains(".dng"))
        #expect(defaults.contains(".raf"))
        #expect(defaults.contains(".rw2"))
        #expect(defaults.contains(".orf"))
        #expect(defaults.contains(".pef"))
        #expect(defaults.count == 9)
    }

    @Test func testLoadConfig_DefaultWhenNoFile() {
        let extensions = ConfigManager.loadConfig()
        #expect(extensions == ConfigManager.defaultRawExtensions)
    }

    @Test func testLoadConfig_ValidConfigFile() throws {
        let tempDir = try makeTempDir(prefix: "ConfigValidTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\".arw\", \".cr2\", \".nef\"]}".write(
            to: configFile, atomically: true, encoding: .utf8
        )

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions.contains(".arw"))
        #expect(extensions.contains(".cr2"))
        #expect(extensions.contains(".nef"))
        #expect(extensions.count == 3)
    }

    @Test func testLoadConfig_ExtensionWithoutDot() throws {
        let tempDir = try makeTempDir(prefix: "ConfigNoDotTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\"arw\", \"cr2\"]}".write(
            to: configFile, atomically: true, encoding: .utf8
        )

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions.contains(".arw"))
        #expect(extensions.contains(".cr2"))
    }

    @Test func testLoadConfig_UppercaseExtensions() throws {
        let tempDir = try makeTempDir(prefix: "ConfigUpperTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\".ARW\", \".CR2\"]}".write(
            to: configFile, atomically: true, encoding: .utf8
        )

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions.contains(".arw"))
        #expect(extensions.contains(".cr2"))
    }

    @Test func testLoadConfig_DuplicateExtensions() throws {
        let tempDir = try makeTempDir(prefix: "ConfigDupTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\".arw\", \".arw\", \".cr2\", \".CR2\"]}".write(
            to: configFile, atomically: true, encoding: .utf8
        )

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions.contains(".arw"))
        #expect(extensions.contains(".cr2"))
        #expect(extensions.count == 2)
    }

    @Test func testLoadConfig_ExtraKeys() throws {
        let tempDir = try makeTempDir(prefix: "ConfigExtraTest")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\".arw\"], \"OtherKey\": \"value\", \"Version\": 1}".write(
            to: configFile, atomically: true, encoding: .utf8
        )

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions.contains(".arw"))
    }
}
