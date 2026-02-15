import Foundation
import ServiceManagement

/// Manages launch at login using SMAppService (macOS 13+)
@MainActor
class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var status: SMAppService.Status = .notRegistered

    private let service: SMAppService

    private init() {
        // For main app bundle
        self.service = SMAppService.mainApp
        updateStatus()
    }

    /// Check current registration status
    func updateStatus() {
        status = service.status
        isEnabled = (status == .enabled)
    }

    /// Enable launch at login
    func enable() throws {
        guard status != .enabled else { return }

        try service.register()
        updateStatus()
    }

    /// Disable launch at login
    func disable() throws {
        guard status == .enabled else { return }

        try service.unregister()
        updateStatus()
    }

    /// Toggle launch at login
    func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }

    /// Get human-readable status message
    var statusMessage: String {
        switch status {
        case .enabled:
            return "SnippetLibrary will launch automatically when you log in"
        case .notRegistered:
            return "SnippetLibrary will not launch at login"
        case .notFound:
            return "App not found in expected location"
        case .requiresApproval:
            return "Launch at login requires approval in System Settings > General > Login Items"
        @unknown default:
            return "Unknown status"
        }
    }

    /// Whether the user needs to take action in System Settings
    var requiresUserAction: Bool {
        status == .requiresApproval
    }
}
