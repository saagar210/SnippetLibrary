import SwiftUI

struct SnippetEditorView: View {
    let snippet: Snippet?
    let onSave: (Snippet) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String
    @State private var language: String
    @State private var isFavorite: Bool

    init(snippet: Snippet?, onSave: @escaping (Snippet) -> Void, onCancel: @escaping () -> Void) {
        self.snippet = snippet
        self.onSave = onSave
        self.onCancel = onCancel

        _title = State(initialValue: snippet?.title ?? "")
        _content = State(initialValue: snippet?.content ?? "")
        _language = State(initialValue: snippet?.language ?? "plaintext")
        _isFavorite = State(initialValue: snippet?.isFavorite ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(snippet == nil ? "New Snippet" : "Edit Snippet")
                    .font(.headline)

                Spacer()

                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.isEmpty || content.isEmpty)
            }
            .padding()
            .background(Color(.controlBackgroundColor))

            Divider()

            // Form
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    Picker("Language", selection: $language) {
                        Text("Plain Text").tag("plaintext")
                        Text("Swift").tag("swift")
                        Text("Python").tag("python")
                        Text("Bash").tag("bash")
                        Text("JavaScript").tag("javascript")
                        Text("SQL").tag("sql")
                        Text("JSON").tag("json")
                        Text("Markdown").tag("markdown")
                    }

                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 600, height: 500)
    }

    private func save() {
        let now = Date()
        let saved = Snippet(
            id: snippet?.id,
            title: title,
            content: content,
            language: language.isEmpty ? "plaintext" : language,
            isFavorite: isFavorite,
            usageCount: snippet?.usageCount ?? 0,
            createdAt: snippet?.createdAt ?? now,
            updatedAt: now
        )
        onSave(saved)
    }
}
