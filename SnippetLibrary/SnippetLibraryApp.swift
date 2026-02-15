import SwiftUI

@main
struct SnippetLibraryApp: App {
    @State private var panelController = SearchPanelController()
    @State private var isInitialized = false

    var body: some Scene {
        // Menu bar presence
        MenuBarExtra("SnippetLibrary", systemImage: "doc.text") {
            MenuBarView(panelController: panelController)
                .task {
                    if !isInitialized {
                        await initialize()
                        isInitialized = true
                    }
                }
        }

        // Snippet manager window (opened on demand)
        Window("Snippet Manager", id: "snippet-manager") {
            SnippetListView()
        }
        .defaultSize(width: 900, height: 600)

        // Settings window
        Settings {
            SettingsView()
        }
    }

    @MainActor
    private func initialize() async {
        setupHotkey()
        checkPermissions()
    }

    @MainActor
    private func setupHotkey() {
        HotkeyService.shared.onHotkeyPressed = { [panelController] in
            panelController.show()
        }
        HotkeyService.shared.start()
    }

    @MainActor
    private func checkPermissions() {
        if !HotkeyService.shared.checkPermissions() {
            HotkeyService.shared.requestPermissions()
        }
        if !AXIsProcessTrusted() {
            // Request accessibility permission with prompt
            let key = "AXTrustedCheckOptionPrompt" as CFString
            let options = [key: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}
