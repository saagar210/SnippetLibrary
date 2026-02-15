import Carbon
import CoreGraphics
import os

@MainActor
class HotkeyService: @unchecked Sendable {
    static let shared = HotkeyService()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onHotkeyPressed: (() -> Void)?
    private let logger = Logger(subsystem: "com.snippetlibrary", category: "hotkey")

    private init() {}

    func start() {
        guard checkPermissions() else {
            logger.warning("Input Monitoring permission not granted")
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        // The callback must be a C function pointer
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,        // .listenOnly = Input Monitoring permission
            eventsOfInterest: eventMask,
            callback: hotkeyCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logger.error("Failed to create CGEventTap. Permission issue?")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.info("Hotkey service started")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    func checkPermissions() -> Bool {
        return CGPreflightListenEventAccess()
    }

    func requestPermissions() {
        CGRequestListenEventAccess()
    }
}

// C-function callback for CGEventTap
private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard type == .keyDown,
          let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let service = Unmanaged<HotkeyService>.fromOpaque(userInfo).takeUnretainedValue()

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags

    // Cmd+Shift+Space: keyCode 49 = Space
    let isCmd = flags.contains(.maskCommand)
    let isShift = flags.contains(.maskShift)
    let isNoOtherMods = !flags.contains(.maskAlternate) && !flags.contains(.maskControl)

    if keyCode == 49 && isCmd && isShift && isNoOtherMods {
        Task { @MainActor in
            service.onHotkeyPressed?()
        }
    }

    return Unmanaged.passUnretained(event)
}
