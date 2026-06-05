import SwiftUI
import AppKit
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var destinationPath: String = ""
    @Published var eventName: String = ""
    @Published var selectedSdPath: String = ""
    @Published var isProcessing: Bool = false
    @Published var countLabel: String = "RAW:0 / JPG:0 / MP4:0"
    @Published var progressLabel: String = "待機中"
    @Published var logText: String = ""
    @Published var autoStart: Bool = false
    @Published var startInBackground: Bool = true

    var scannedFiles: [String] = []
    let scanner: MediaScanning
    let processor: MediaProcessing
    let sdDetector: SDCardDetecting
    var onShowWindow: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private let maxLogLines = 1000

    init() {
        let rawExtensions = ConfigManager.loadConfig()
        scanner = MediaScanner(rawExtensions: rawExtensions)
        processor = MediaProcessor(scanner: scanner)
        sdDetector = SDCardDetector()

        loadState()
        setupBindings()

        sdDetector.start { [weak self] path in
            Task { @MainActor in
                self?.handleSDDetected(path)
            }
        }
    }

    private func setupBindings() {
        $destinationPath
            .dropFirst()
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)

        $selectedSdPath
            .dropFirst()
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)

        $autoStart
            .dropFirst()
            .sink { [weak self] enabled in
                _ = LoginItemManager.setAutoStart(enabled)
                self?.saveState()
            }
            .store(in: &cancellables)

        $startInBackground
            .dropFirst()
            .sink { [weak self] _ in self?.saveState() }
            .store(in: &cancellables)
    }

    private func getPicturesDirectory() -> String {
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!.path
    }

    func loadState() {
        guard let state = StateManager.loadState() else {
            destinationPath = getPicturesDirectory()
            autoStart = LoginItemManager.isAutoStartEnabled()
            return
        }

        destinationPath = state.destinationPath.isEmpty ? getPicturesDirectory() : state.destinationPath
        selectedSdPath = state.selectedSdPath
        autoStart = state.autoStart
        startInBackground = state.startInBackground
    }

    func saveState() {
        let state = AppStateData(
            destinationPath: destinationPath,
            selectedSdPath: selectedSdPath,
            autoStart: autoStart,
            startInBackground: startInBackground
        )
        _ = StateManager.saveState(state)
    }

    func appendLog(_ line: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logText += "\(timestamp) \(line)\n"

        let lines = logText.components(separatedBy: "\n")
        if lines.count > maxLogLines {
            logText = lines.suffix(maxLogLines).joined(separator: "\n")
        }
    }

    func selectDestination() {
        openFolderPanel(message: "保存先を選択") { [weak self] path in
            self?.destinationPath = path
        }
    }

    func selectSDCard() {
        openFolderPanel(message: "SDカードを選択") { [weak self] path in
            Task { @MainActor in
                await self?.selectSdAndScan(path: path)
            }
        }
    }

    private func openFolderPanel(message: String, completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = message
        panel.prompt = "選択"

        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.url {
                    completion(url.path)
                }
            }
        } else {
            if panel.runModal() == .OK, let url = panel.url {
                completion(url.path)
            }
        }
    }

    func handleSDDetected(_ path: String) {
        appendLog("SDカード検出: \(path)")
        Task {
            let success = await selectSdAndScan(path: path, autoDetected: true)
            if success {
                onShowWindow?()
            }
        }
    }

    @MainActor
    func selectSdAndScan(path: String, autoDetected: Bool = false) async -> Bool {
        if isProcessing { return false }

        selectedSdPath = path
        resetScannedState()
        appendLog("スキャン開始: \(path)")

        let files = await Task.detached { [scanner] in
            scanner.enumerateMediaFiles(root: path)
        }.value

        if autoDetected && files.isEmpty {
            appendLog("自動選択スキップ（メディアなし）: \(path)")
            return false
        }

        scannedFiles = files
        saveState()
        let (raw, jpg, mp4) = scanner.countByType(files)
        countLabel = "RAW:\(raw) / JPG:\(jpg) / MP4:\(mp4)"
        appendLog("\(files.count) 件検出 / RAW:\(raw) / JPG:\(jpg) / MP4:\(mp4)")
        return true
    }

    func resetScannedState() {
        scannedFiles = []
        countLabel = "RAW:0 / JPG:0 / MP4:0"
    }

    func startProcessing() async {
        if isProcessing { return }
        if destinationPath.isEmpty || eventName.isEmpty || scannedFiles.isEmpty {
            appendLog("保存先・イベント名・SDカード選択を確認してください。")
            return
        }

        isProcessing = true
        progressLabel = "処理中... 0/\(scannedFiles.count)"

        let filesToProcess = scannedFiles
        let destination = destinationPath
        let eventNameValue = eventName

        let result = await Task.detached { [processor, weak self] in
            await processor.processFiles(filesToProcess, destination: destination, eventName: eventNameValue) { processed, total in
                Task { @MainActor in
                    self?.progressLabel = "処理中... \(processed)/\(total)"
                }
            }
        }.value

        appendLog("完了: RAW:\(result.raw) / JPG:\(result.jpg) / MP4:\(result.mp4) / 重複スキップ:\(result.skipDuplicate) / 非対応スキップ:\(result.skipUnsupported) / 失敗:\(result.failed)")
        if !result.errors.isEmpty {
            for (file, error) in result.errors.prefix(5) {
                appendLog("  エラー: \(file) - \(error)")
            }
            if result.errors.count > 5 {
                appendLog("  他 \(result.errors.count - 5) 件のエラー")
            }
        }
        appendLog("保存先: \(result.basePath)")
        saveState()

        isProcessing = false
        progressLabel = "待機中"
    }

    func initializeSdSelection() async {
        if !selectedSdPath.isEmpty && sdDetector.isCandidateSD(selectedSdPath) {
            let reused = await selectSdAndScan(path: selectedSdPath, autoDetected: true)
            if reused { return }
        }

        let volumes = sdDetector.getMountedVolumes()
        let candidates = volumes.filter { sdDetector.isCandidateSD($0) }.sorted()
        for volume in candidates {
            let found = await selectSdAndScan(path: volume, autoDetected: true)
            if found { return }
        }
    }
}
