import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PermissionsSettingsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }

            OllamaSettingsView()
                .tabItem {
                    Label("Ollama", systemImage: "cpu")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @StateObject private var launchService = LaunchAtLoginService.shared
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("Startup") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch at Login", isOn: Binding(
                        get: { launchService.isEnabled },
                        set: { _ in toggleLaunchAtLogin() }
                    ))

                    Text(launchService.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if launchService.requiresUserAction {
                        Button("Open System Settings") {
                            openLoginItemsSettings()
                        }
                        .font(.caption)
                    }
                }
            }

            Section("Hotkey") {
                HStack {
                    Text("Global Trigger:")
                    Spacer()
                    Text("⌘⇧Space")
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Section("About") {
                LabeledContent("Version", value: "0.4.0 (Phase 4)")
                LabeledContent("Database", value: AppDatabase.databasePath())
            }
        }
        .formStyle(.grouped)
        .onAppear {
            launchService.updateStatus()
        }
        .alert("Launch at Login", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func toggleLaunchAtLogin() {
        do {
            try launchService.toggle()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct PermissionsSettingsView: View {
    @State private var inputMonitoringGranted = false
    @State private var accessibilityGranted = false

    var body: some View {
        Form {
            Section("Required Permissions") {
                PermissionRow(
                    title: "Input Monitoring",
                    description: "Detect global hotkey (Cmd+Shift+Space)",
                    isGranted: inputMonitoringGranted,
                    action: {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
                    }
                )

                PermissionRow(
                    title: "Accessibility",
                    description: "Insert snippets into other apps",
                    isGranted: accessibilityGranted,
                    action: {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                )
            }
        }
        .formStyle(.grouped)
        .onAppear {
            checkPermissions()
        }
    }

    private func checkPermissions() {
        inputMonitoringGranted = CGPreflightListenEventAccess()
        accessibilityGranted = AXIsProcessTrusted()
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant") {
                    action()
                }
            }
        }
    }
}
