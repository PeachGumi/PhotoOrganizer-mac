import Foundation
import AppKit

protocol SDCardDetecting {
    func start(onDetected: @escaping (String) -> Void)
    func getMountedVolumes() -> [String]
    func isCandidateSD(_ path: String) -> Bool
    func stop()
}

class SDCardDetector: NSObject, SDCardDetecting {
    private var pollTimer: Timer?
    private var knownVolumes: Set<String> = []
    private var onSDDetected: ((String) -> Void)?
    private let systemPaths: Set<String> = ["/", "/System/Volumes/Data"]

    func start(onDetected: @escaping (String) -> Void) {
        self.onSDDetected = onDetected

        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(didMount(_:)), name: NSWorkspace.didMountNotification, object: nil)
        nc.addObserver(self, selector: #selector(didUnmount(_:)), name: NSWorkspace.didUnmountNotification, object: nil)

        knownVolumes = Set(getMountedVolumes())

        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    @objc private func didMount(_ notification: Notification) {
        guard let url = notification.userInfo?["NSWorkspaceVolumeURLKey"] as? URL else { return }
        let path = url.path
        DispatchQueue.main.async {
            self.knownVolumes.insert(path)
            self.checkVolume(path)
        }
    }

    @objc private func didUnmount(_ notification: Notification) {
        guard let url = notification.userInfo?["NSWorkspaceVolumeURLKey"] as? URL else { return }
        knownVolumes.remove(url.path)
    }

    private func poll() {
        let current = Set(getMountedVolumes())
        let newVolumes = current.subtracting(knownVolumes)
        knownVolumes = current
        for volume in newVolumes {
            checkVolume(volume)
        }
    }

    private func checkVolume(_ path: String) {
        guard isCandidateSD(path) else { return }
        onSDDetected?(path)
    }

    func getMountedVolumes() -> [String] {
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.isVolumeKey],
            options: [.skipHiddenVolumes]
        ) else {
            return []
        }
        return urls.map { $0.path }
    }

    func isCandidateSD(_ path: String) -> Bool {
        if systemPaths.contains(path) { return false }

        let fm = FileManager.default
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent("DCIM")) ||
           fm.fileExists(atPath: (path as NSString).appendingPathComponent("PRIVATE")) {
            return true
        }

        return false
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
