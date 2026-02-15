import SwiftUI
import AppKit

struct MenuBarView: View {
    let panelController: SearchPanelController
    @Environment(\.openWindow) private var openWindow
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { panelController.show() }) {
                Label("Search Snippets (Cmd+Shift+Space)", systemImage: "magnifyingglass")
            }

            Divider()

            Button(action: { openWindow(id: "snippet-manager") }) {
                Label("Manage Snippets...", systemImage: "list.bullet.rectangle")
            }

            Divider()

            Button(action: exportSnippets) {
                Label("Export Snippets...", systemImage: "square.and.arrow.up")
            }

            Button(action: importSnippets) {
                Label("Import Snippets...", systemImage: "square.and.arrow.down")
            }

            Divider()

            Button(action: { openWindow(id: "settings") }) {
                Label("Settings...", systemImage: "gear")
            }

            Divider()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit SnippetLibrary", systemImage: "xmark.circle")
            }
        }
        .padding(.vertical, 4)
        .alert("Import/Export", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Actions

    private func exportSnippets() {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "snippets-\(Date().formatted(.iso8601.year().month().day())).json"
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            Task { @MainActor in
                do {
                    let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
                    let snippets = try repository.fetchAll()
                    try ImportExportService.exportToFile(url: url, snippets: snippets, repository: repository)

                    alertMessage = "Exported \(snippets.count) snippet\(snippets.count == 1 ? "" : "s") successfully"
                    showingAlert = true
                } catch {
                    alertMessage = "Export failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private func importSnippets() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        openPanel.begin { response in
            guard response == .OK, let url = openPanel.urls.first else { return }

            Task { @MainActor in
                // Ask user if they want to replace existing snippets
                let alert = NSAlert()
                alert.messageText = "Import Snippets"
                alert.informativeText = "Do you want to replace existing snippets or merge with them?"
                alert.addButton(withTitle: "Merge")
                alert.addButton(withTitle: "Replace All")
                alert.addButton(withTitle: "Cancel")
                alert.alertStyle = .informational

                let choice = alert.runModal()

                guard choice != .alertThirdButtonReturn else { return }

                let replaceExisting = (choice == .alertSecondButtonReturn)

                do {
                    let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
                    let result = try ImportExportService.importFromFile(
                        url: url,
                        repository: repository,
                        replaceExisting: replaceExisting
                    )

                    if result.errors.isEmpty {
                        alertMessage = result.message
                    } else {
                        alertMessage = result.message + "\n\nErrors:\n" + result.errors.joined(separator: "\n")
                    }
                    showingAlert = true
                } catch {
                    alertMessage = "Import failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}
