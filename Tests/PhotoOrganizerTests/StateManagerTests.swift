import Testing
import Foundation
@testable import PhotoOrganizer

struct StateManagerTests {
    @Test func testStatePath() {
        let path = StateManager.statePath
        #expect(path.contains("PhotoOrganizer"))
        #expect(path.contains("state.json"))
        #expect(path.contains("Application Support"))
    }

    @Test func testStatePath_IsInUserDomain() {
        let path = StateManager.statePath
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        #expect(path.hasPrefix(homeDir))
    }

    @Test func testStateDirectory_IsCreated() {
        let dir = StateManager.stateDirectory
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
        #expect(exists)
        #expect(isDir.boolValue)
    }

    @Test func testSaveState_ReturnsTrue() {
        let state = AppStateData(
            destinationPath: "/test/path",
            selectedSdPath: "/test/sd",
            autoStart: false,
            startInBackground: false
        )
        let result = StateManager.saveState(state)
        #expect(result == true)
    }
}
