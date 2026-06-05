import Testing
import Foundation
@testable import PhotoOrganizer

struct StateManagerTests {
    @Test func testSaveAndLoadState() throws {
        let originalState = AppStateData(
            destinationPath: "/test/destination",
            selectedSdPath: "/Volumes/SDCARD",
            autoStart: true,
            startInBackground: false
        )

        let saveResult = StateManager.saveState(originalState)
        #expect(saveResult == true)

        let loadedState = StateManager.loadState()

        #expect(loadedState != nil)
        #expect(loadedState?.destinationPath == originalState.destinationPath)
        #expect(loadedState?.selectedSdPath == originalState.selectedSdPath)
        #expect(loadedState?.autoStart == originalState.autoStart)
        #expect(loadedState?.startInBackground == originalState.startInBackground)

        let emptyState = AppStateData(
            destinationPath: "",
            selectedSdPath: "",
            autoStart: false,
            startInBackground: true
        )
        _ = StateManager.saveState(emptyState)
    }

    @Test func testStatePath() {
        let path = StateManager.statePath
        #expect(path.contains("PhotoOrganizer"))
        #expect(path.contains("state.json"))
        #expect(path.contains("Application Support"))
    }
}
