import SwiftUI
import AppKit

@main
struct PhotoOrganizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appDelegate.appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 820, height: 600)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var statusItem: NSStatusItem?
    var mainWindow: NSWindow?
    var windowDelegate: WindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.onShowWindow = { [weak self] in
            self?.showWindow()
        }

        setupStatusBar()

        if appState.startInBackground {
            NSApp.setActivationPolicy(.accessory)
            hideAllWindows()
        } else {
            showWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.saveState()
        appState.sdDetector.stop()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Photo Organizer (Mac)")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Photo Organizer (Mac)を表示", action: #selector(showWindow), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "終了", action: #selector(quitApp), keyEquivalent: "q")

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    @objc func showWindow() {
        NSApp.setActivationPolicy(.regular)

        if mainWindow == nil {
            let contentView = ContentView().environmentObject(appState)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = NSHostingView(rootView: contentView)
            window.title = "Photo Organizer (Mac)"
            window.isReleasedWhenClosed = false
            window.center()

            let delegate = WindowDelegate { [weak self] in
                self?.hideWindow()
            }
            window.delegate = delegate
            self.windowDelegate = delegate

            mainWindow = window
        }

        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideWindow() {
        mainWindow?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    private func hideAllWindows() {
        for window in NSApp.windows {
            window.orderOut(nil)
        }
    }

    @objc func quitApp() {
        appState.saveState()
        appState.sdDetector.stop()
        NSApp.terminate(nil)
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        onClose()
        return false
    }
}
