import SwiftUI

struct SearchPanelView: View {
    @State private var searchText = ""
    @State private var snippets: [Snippet] = []
    @State private var recentlyUsed: [Snippet] = []
    @State private var languages: [String] = []
    @State private var selectedLanguage: String? = nil
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    let onSelect: (Snippet) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            TextField("Search snippets...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(12)
                .focused($isSearchFocused)

            // Language filter (only show if we have snippets with languages)
            if !languages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        LanguageFilterButton(
                            title: "All",
                            isSelected: selectedLanguage == nil,
                            action: { selectedLanguage = nil }
                        )

                        ForEach(languages, id: \.self) { language in
                            LanguageFilterButton(
                                title: language.capitalized,
                                isSelected: selectedLanguage == language,
                                action: { selectedLanguage = language }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            Divider()

            // Results
            if displaySnippets.isEmpty {
                EmptyStateView(message: searchText.isEmpty
                    ? "No snippets yet. Open Snippet Manager to add some."
                    : "No matches for \"\(searchText)\"")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        // Recently used section (only when no search query)
                        if searchText.isEmpty && !recentlyUsed.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recently Used")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)

                                ForEach(recentlyUsed) { snippet in
                                    SnippetSearchRowView(
                                        snippet: snippet,
                                        isSelected: displaySnippets.firstIndex(where: { $0.id == snippet.id }).map { $0 == selectedIndex } ?? false,
                                        showUsageCount: true
                                    )
                                    .onTapGesture { onSelect(snippet) }
                                }

                                Divider()
                                    .padding(.vertical, 4)

                                Text("All Snippets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                            }
                        }

                        // All snippets
                        ForEach(Array(displaySnippets.prefix(20).enumerated()), id: \.element.id) { index, snippet in
                            SnippetSearchRowView(
                                snippet: snippet,
                                isSelected: index == selectedIndex,
                                showUsageCount: searchText.isEmpty
                            )
                            .onTapGesture { onSelect(snippet) }
                        }
                    }
                    .padding(4)
                }
            }
        }
        .frame(width: 500, height: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
            performSearch()
        }
        .onChange(of: selectedLanguage) { _, _ in
            selectedIndex = 0
            performSearch()
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard !displaySnippets.isEmpty else {
                selectedIndex = 0
                return .handled
            }
            selectedIndex = min(displaySnippets.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.return) {
            if displaySnippets.indices.contains(selectedIndex) {
                onSelect(displaySnippets[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .onAppear {
            isSearchFocused = true
            loadData()
        }
    }

    private var displaySnippets: [Snippet] {
        snippets
    }

    private func loadData() {
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            languages = try repository.fetchLanguages()
            recentlyUsed = try repository.fetchRecentlyUsed(limit: 5)
            performSearch()
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    private func performSearch() {
        do {
            let repository = SnippetRepository(dbQueue: AppDatabase.shared.dbQueue)
            snippets = try repository.search(query: searchText, language: selectedLanguage)
            if snippets.isEmpty {
                selectedIndex = 0
            } else {
                selectedIndex = min(selectedIndex, snippets.count - 1)
            }
        } catch {
            print("Failed to search snippets: \(error)")
        }
    }
}

struct LanguageFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct SnippetSearchRowView: View {
    let snippet: Snippet
    let isSelected: Bool
    var showUsageCount: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(snippet.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let language = snippet.language, !language.isEmpty, language != "plaintext" {
                        LanguageBadge(language: language)
                    }
                }

                Text(snippet.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if showUsageCount && snippet.usageCount > 0 {
                Text("\(snippet.usageCount)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
