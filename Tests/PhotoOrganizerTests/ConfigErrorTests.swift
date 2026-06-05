import Testing
import Foundation
@testable import PhotoOrganizer

struct ConfigErrorTests {
    @Test func testInvalidJsonFormat() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("InvalidJsonTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "this is not valid json".write(to: configFile, atomically: true, encoding: .utf8)

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions == ConfigManager.defaultRawExtensions)
    }

    @Test func testEmptyJsonFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyJsonTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "".write(to: configFile, atomically: true, encoding: .utf8)

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions == ConfigManager.defaultRawExtensions)
    }

    @Test func testEmptyArrayConfig() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyArrayTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": []}".write(to: configFile, atomically: true, encoding: .utf8)

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions == ConfigManager.defaultRawExtensions)
    }

    @Test func testInvalidExtensionFormat() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("InvalidExtTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\"\", \"   \", \".\", \"..\"]}".write(to: configFile, atomically: true, encoding: .utf8)

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions == ConfigManager.defaultRawExtensions)
    }

    @Test func testMixedValidInvalidExtensions() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MixedExtTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"RawExtensions\": [\".arw\", \"\", \".cr2\", \"   \"]}".write(to: configFile, atomically: true, encoding: .utf8)

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions.contains(".arw"))
        #expect(extensions.contains(".cr2"))
    }

    @Test func testMissingRawExtensionsKey() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MissingKeyTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        try "{\"OtherKey\": \"value\"}".write(to: configFile, atomically: true, encoding: .utf8)

        let extensions = ConfigManager.loadConfig(configPath: configFile.path)
        #expect(extensions == ConfigManager.defaultRawExtensions)
    }
}
