import SwiftUI
import AppKit

class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hidesOnDeactivate = false       // Keep visible when app loses focus
        becomesKeyOnlyIfNeeded = true   // Don't steal focus
        animationBehavior = .utilityWindow
        isMovableByWindowBackground = false
    }

    // Allow the search field to become first responder
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // Close on Escape
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
