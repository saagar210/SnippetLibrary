import AppKit
import SwiftUI

@MainActor
@Observable
class SearchPanelController {
    private var panel: FloatingPanel?

    func show() {
        dismiss()  // close any existing panel

        let panelRect = NSRect(x: 0, y: 0, width: 500, height: 360)
        let panel = FloatingPanel(contentRect: panelRect)

        let searchView = SearchPanelView(onSelect: { [weak self] snippet in
            self?.insertSnippet(snippet)
        }, onDismiss: { [weak self] in
            self?.dismiss()
        })

        panel.contentView = NSHostingView(rootView: searchView)

        positionNearCursor(panel)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func dismiss() {
        panel?.close()
        panel = nil
    }

    private func positionNearCursor(_ panel: FloatingPanel) {
        let mouseLocation = NSEvent.mouseLocation  // screen coordinates
        guard let screen = NSScreen.screens.first(where: {
            $0.frame.contains(mouseLocation)
        }) ?? NSScreen.main else { return }

        var origin = mouseLocation
        origin.x -= panel.frame.width / 2   // center horizontally on cursor
        origin.y -= panel.frame.height + 10  // place below cursor

        // Clamp to screen bounds
        let screenFrame = screen.visibleFrame
        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - panel.frame.width))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - panel.frame.height))

        panel.setFrameOrigin(origin)
    }

    private func insertSnippet(_ snippet: Snippet) {
        dismiss()
        Task {
            do {
                try await PasteService.shared.insertText(snippet.content)
                // Increment usage count
                if let snippetId = snippet.id {
                    try SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
                        .incrementUsageCount(id: snippetId)
                }
            } catch {
                print("Failed to insert snippet: \(error)")
            }
        }
    }
}
