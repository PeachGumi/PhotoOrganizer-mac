import Testing
import Foundation
@testable import PhotoOrganizer

struct ConfigManagerTests {
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
}
