import Foundation

class StateManager {
    static let stateDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PhotoOrganizer-mac")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static var statePath: String {
        stateDirectory.appendingPathComponent("state.json").path
    }

    static func loadState() -> AppStateData? {
        let path = statePath
        guard FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let state = try? JSONDecoder().decode(AppStateData.self, from: data) else {
            return nil
        }
        return state
    }

    static func saveState(_ state: AppStateData) -> Bool {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: URL(fileURLWithPath: statePath), options: .atomic)
            return true
        } catch {
            #if DEBUG
            print("Failed to save state: \(error)")
            #endif
            return false
        }
    }
}
