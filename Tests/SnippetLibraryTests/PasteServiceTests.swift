import XCTest
@testable import SnippetLibrary

@MainActor
private final class OperationLog {
    var events: [String] = []
}

@MainActor
private final class MockPasteboardClient: PasteboardClient, @unchecked Sendable {
    private let log: OperationLog
    private(set) var restoredSnapshots: [PasteboardSnapshot] = []
    private let snapshotToReturn: PasteboardSnapshot

    init(log: OperationLog, snapshotToReturn: PasteboardSnapshot) {
        self.log = log
        self.snapshotToReturn = snapshotToReturn
    }

    func snapshot() -> PasteboardSnapshot {
        log.events.append("snapshot")
        return snapshotToReturn
    }

    func setString(_ text: String) {
        log.events.append("set:\(text)")
    }

    func restore(from snapshot: PasteboardSnapshot) {
        log.events.append("restore")
        restoredSnapshots.append(snapshot)
    }
}

@MainActor
private final class MockPasteEventClient: PasteEventClient, @unchecked Sendable {
    private let log: OperationLog

    init(log: OperationLog) {
        self.log = log
    }

    func postPaste() {
        log.events.append("paste")
    }
}

final class PasteServiceTests: XCTestCase {
    func testInsertTextOrdersOperations() async throws {
        let log = await MainActor.run { OperationLog() }
        let originalSnapshot = PasteboardSnapshot(items: [["public.utf8-plain-text": Data("original".utf8)]])

        let pasteboard = await MainActor.run { MockPasteboardClient(log: log, snapshotToReturn: originalSnapshot) }
        let events = await MainActor.run { MockPasteEventClient(log: log) }

        let service = PasteService(
            pasteboardClient: pasteboard,
            pasteEventClient: events,
            restoreDelay: .zero,
            sleepFunction: { _ in
                await MainActor.run {
                    log.events.append("sleep")
                }
            }
        )

        try await service.insertText("hello")

        let recorded = await MainActor.run { log.events }
        XCTAssertEqual(recorded, ["snapshot", "set:hello", "paste", "sleep", "restore"])

        let restored = await MainActor.run { pasteboard.restoredSnapshots }
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored.first?.items.first?["public.utf8-plain-text"], Data("original".utf8))
    }

    func testConcurrentInsertsAreSerialized() async throws {
        let log = await MainActor.run { OperationLog() }
        let snapshot = PasteboardSnapshot(items: [["public.utf8-plain-text": Data("initial".utf8)]])

        let pasteboard = await MainActor.run { MockPasteboardClient(log: log, snapshotToReturn: snapshot) }
        let events = await MainActor.run { MockPasteEventClient(log: log) }

        let service = PasteService(
            pasteboardClient: pasteboard,
            pasteEventClient: events,
            restoreDelay: .milliseconds(1),
            sleepFunction: { _ in
                await MainActor.run {
                    log.events.append("sleep")
                }
                await Task.yield()
            }
        )

        let first = Task {
            try await service.insertText("one")
        }
        await Task.yield()
        let second = Task {
            try await service.insertText("two")
        }

        try await first.value
        try await second.value

        let recorded = await MainActor.run { log.events }
        XCTAssertEqual(
            recorded,
            [
                "snapshot", "set:one", "paste", "sleep", "restore",
                "snapshot", "set:two", "paste", "sleep", "restore"
            ]
        )
    }
}
