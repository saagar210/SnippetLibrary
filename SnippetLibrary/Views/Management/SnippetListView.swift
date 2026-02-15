import SwiftUI
import GRDB

struct SnippetListView: View {
    @State private var snippets: [Snippet] = []
    @State private var selectedSnippet: Snippet?
    @State private var searchText = ""
    @State private var isShowingEditor = false
    @State private var editingSnippet: Snippet?

    var body: some View {
        NavigationSplitView {
            // Sidebar: snippet list
            VStack(spacing: 0) {
                // Search bar
                TextField("Search snippets...", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.controlBackgroundColor))

                Divider()

                // Snippet list
                List(filteredSnippets, selection: $selectedSnippet) { snippet in
                    SnippetRowItem(snippet: snippet)
                        .tag(snippet)
                }
                .listStyle(.sidebar)
            }
            .navigationTitle("Snippets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNewSnippet) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let snippet = selectedSnippet {
                SnippetDetailView(snippet: snippet, onEdit: {
                    editingSnippet = snippet
                    isShowingEditor = true
                }, onDelete: {
                    deleteSnippet(snippet)
                })
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "text.snippet",
                    description: Text("Select a snippet to view details")
                )
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            if let snippet = editingSnippet {
                SnippetEditorView(snippet: snippet, onSave: { updated in
                    updateSnippet(updated)
                    isShowingEditor = false
                }, onCancel: {
                    isShowingEditor = false
                })
            } else {
                SnippetEditorView(snippet: nil, onSave: { new in
                    saveNewSnippet(new)
                    isShowingEditor = false
                }, onCancel: {
                    isShowingEditor = false
                })
            }
        }
        .onAppear {
            loadSnippets()
        }
    }

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return snippets
        }
        let query = searchText.lowercased()
        return snippets.filter { snippet in
            snippet.title.lowercased().contains(query) ||
            snippet.content.lowercased().contains(query)
        }
    }

    private func loadSnippets() {
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            snippets = try repository.fetchAll()
        } catch {
            print("Failed to load snippets: \(error)")
        }
    }

    private func createNewSnippet() {
        editingSnippet = nil
        isShowingEditor = true
    }

    private func saveNewSnippet(_ snippet: Snippet) {
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            var mutableSnippet = snippet
            try repository.insert(&mutableSnippet)
            loadSnippets()
        } catch {
            print("Failed to save snippet: \(error)")
        }
    }

    private func updateSnippet(_ snippet: Snippet) {
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            try repository.update(snippet)
            loadSnippets()
        } catch {
            print("Failed to update snippet: \(error)")
        }
    }

    private func deleteSnippet(_ snippet: Snippet) {
        guard let id = snippet.id else { return }
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            try repository.delete(id: id)
            selectedSnippet = nil
            loadSnippets()
        } catch {
            print("Failed to delete snippet: \(error)")
        }
    }
}

struct SnippetRowItem: View {
    let snippet: Snippet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(snippet.title)
                    .font(.body)
                    .lineLimit(1)

                Spacer()

                if snippet.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            Text(snippet.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}
