import SwiftUI

struct OllamaSettingsView: View {
    @State private var endpoint: String = ""
    @State private var model: String = ""
    @State private var isEnabled: Bool = false
    @State private var isChecking: Bool = false
    @State private var isAvailable: Bool = false
    @State private var availableModels: [String] = []
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Configuration") {
                Toggle("Enable Semantic Search", isOn: $isEnabled)
                    .onChange(of: isEnabled) { _, newValue in
                        Task {
                            await saveConfiguration()
                        }
                    }

                TextField("Ollama Endpoint", text: $endpoint)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isEnabled)
                    .onSubmit {
                        Task {
                            await saveConfiguration()
                            await checkConnection()
                        }
                    }

                HStack {
                    if availableModels.isEmpty {
                        TextField("Model Name", text: $model)
                            .textFieldStyle(.roundedBorder)
                            .disabled(!isEnabled)
                            .onSubmit {
                                Task {
                                    await saveConfiguration()
                                }
                            }
                    } else {
                        Picker("Model", selection: $model) {
                            ForEach(availableModels, id: \.self) { modelName in
                                Text(modelName).tag(modelName)
                            }
                        }
                        .disabled(!isEnabled)
                        .onChange(of: model) { _, _ in
                            Task {
                                await saveConfiguration()
                            }
                        }
                    }
                }
            }

            Section("Connection Status") {
                HStack {
                    Circle()
                        .fill(isAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isAvailable ? "Connected" : "Not Connected")
                        .foregroundColor(.secondary)
                    Spacer()
                    if isChecking {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Check Connection") {
                    Task {
                        await checkConnection()
                    }
                }
                .disabled(!isEnabled || isChecking)
            }

            Section("Help") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Semantic search uses Ollama to find snippets by meaning, not just keywords.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("1. Install Ollama from ollama.ai")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("2. Run: ollama pull nomic-embed-text")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("3. Ollama runs on localhost:11434 by default")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
        .task {
            await loadConfiguration()
            if isEnabled {
                await checkConnection()
            }
        }
    }

    private func loadConfiguration() async {
        let config = await OllamaService.shared.getConfiguration()
        endpoint = config.endpoint
        model = config.model
        isEnabled = config.isEnabled
    }

    private func saveConfiguration() async {
        await OllamaService.shared.configure(
            endpoint: endpoint,
            model: model,
            isEnabled: isEnabled
        )
    }

    private func checkConnection() async {
        isChecking = true
        errorMessage = nil

        let available = await OllamaService.shared.checkAvailability()
        isAvailable = available

        if available {
            do {
                let models = try await OllamaService.shared.fetchModels()
                availableModels = models

                if !models.isEmpty && !models.contains(model) {
                    model = models.first ?? model
                    await saveConfiguration()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            availableModels = []
            errorMessage = "Cannot connect to Ollama. Make sure it's running."
        }

        isChecking = false
    }
}

#Preview {
    OllamaSettingsView()
}
