import AppKit
import CoreGraphics

struct PasteboardSnapshot: Sendable {
    let items: [[String: Data]]
}

@MainActor
protocol PasteboardClient: Sendable {
    func snapshot() -> PasteboardSnapshot
    func setString(_ text: String)
    func restore(from snapshot: PasteboardSnapshot)
}

@MainActor
protocol PasteEventClient: Sendable {
    func postPaste()
}

struct SystemPasteboardClient: PasteboardClient {
    func snapshot() -> PasteboardSnapshot {
        let pasteboard = NSPasteboard.general
        var snapshotItems: [[String: Data]] = []

        for item in pasteboard.pasteboardItems ?? [] {
            var itemData: [String: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    itemData[type.rawValue] = data
                }
            }
            snapshotItems.append(itemData)
        }

        return PasteboardSnapshot(items: snapshotItems)
    }

    func setString(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func restore(from snapshot: PasteboardSnapshot) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard !snapshot.items.isEmpty else { return }

        let restoredItems: [NSPasteboardItem] = snapshot.items.map { itemData in
            let item = NSPasteboardItem()
            for (rawType, data) in itemData {
                item.setData(data, forType: NSPasteboard.PasteboardType(rawValue: rawType))
            }
            return item
        }

        if !restoredItems.isEmpty {
            pasteboard.writeObjects(restoredItems)
        }
    }
}

struct SystemPasteEventClient: PasteEventClient {
    func postPaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}

actor PasteService {
    static let shared = PasteService()

    private let pasteboardClient: any PasteboardClient
    private let pasteEventClient: any PasteEventClient
    private let restoreDelay: Duration
    private let sleepFunction: @Sendable (Duration) async -> Void

    // Chained task serialization prevents actor reentrancy from interleaving restores.
    private var lastOperation: Task<Void, Never>?

    init(
        pasteboardClient: any PasteboardClient = SystemPasteboardClient(),
        pasteEventClient: any PasteEventClient = SystemPasteEventClient(),
        restoreDelay: Duration = .milliseconds(100),
        sleepFunction: @escaping @Sendable (Duration) async -> Void = { delay in
            try? await Task.sleep(for: delay)
        }
    ) {
        self.pasteboardClient = pasteboardClient
        self.pasteEventClient = pasteEventClient
        self.restoreDelay = restoreDelay
        self.sleepFunction = sleepFunction
    }

    func insertText(_ text: String) async throws {
        let previous = lastOperation
        let pasteboardClient = self.pasteboardClient
        let pasteEventClient = self.pasteEventClient
        let restoreDelay = self.restoreDelay
        let sleepFunction = self.sleepFunction

        let operation = Task {
            if let previous {
                await previous.value
            }

            let previousContents = await pasteboardClient.snapshot()
            await pasteboardClient.setString(text)
            await pasteEventClient.postPaste()
            await sleepFunction(restoreDelay)
            await pasteboardClient.restore(from: previousContents)
        }

        lastOperation = operation
        await operation.value
    }
}
