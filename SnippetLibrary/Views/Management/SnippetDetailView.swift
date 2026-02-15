import SwiftUI

struct SnippetDetailView: View {
    let snippet: Snippet
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var tags: [Tag] = []
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snippet.title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack(spacing: 8) {
                            if let language = snippet.language, !language.isEmpty {
                                LanguageBadge(language: language)
                            }

                            Text("Used \(snippet.usageCount) times")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if snippet.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: copyToClipboard) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }

                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Divider()

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)

                    CodeHighlightView(code: snippet.content, language: snippet.language, fontSize: 14)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Tags
                if !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)

                        HStack {
                            ForEach(tags) { tag in
                                Text(tag.name)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created: \(snippet.createdAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Updated: \(snippet.updatedAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(snippet.title)
        .onAppear {
            loadTags()
        }
        .confirmationDialog("Delete Snippet?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.content, forType: .string)
    }

    private func loadTags() {
        guard let id = snippet.id else { return }
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            tags = try repository.fetchTags(for: id)
        } catch {
            print("Failed to load tags: \(error)")
        }
    }
}

struct LanguageBadge: View {
    let language: String

    var body: some View {
        Text(language)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var badgeColor: Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "python": return .blue
        case "bash", "shell": return .green
        case "javascript", "js": return .yellow
        case "sql": return .purple
        case "json": return .indigo
        case "markdown", "md": return .gray
        default: return .secondary
        }
    }
}
