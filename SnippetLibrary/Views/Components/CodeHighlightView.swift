import SwiftUI
import Highlightr

/// View that displays syntax-highlighted code
struct CodeHighlightView: View {
    let code: String
    let language: String?
    let fontSize: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(code: String, language: String? = nil, fontSize: CGFloat = 13) {
        self.code = code
        self.language = language
        self.fontSize = fontSize
    }

    var body: some View {
        if let attributedString = highlightedCode() {
            Text(AttributedString(attributedString))
                .textSelection(.enabled)
                .font(.system(size: fontSize, design: .monospaced))
        } else {
            // Fallback to plain text if highlighting fails
            Text(code)
                .textSelection(.enabled)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func highlightedCode() -> NSAttributedString? {
        guard let highlightr = Highlightr() else { return nil }

        // Use appropriate theme based on color scheme
        highlightr.setTheme(to: colorScheme == .dark ? "atom-one-dark" : "atom-one-light")

        // Set font size
        highlightr.theme.codeFont = .monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Highlight with specified language or auto-detect
        if let language = normalizedLanguage() {
            return highlightr.highlight(code, as: language)
        } else {
            return highlightr.highlight(code)
        }
    }

    /// Normalize language names to highlight.js identifiers
    private func normalizedLanguage() -> String? {
        guard let lang = language?.lowercased() else { return nil }

        // Map common language names to highlight.js language IDs
        let languageMap: [String: String] = [
            "swift": "swift",
            "python": "python",
            "bash": "bash",
            "shell": "bash",
            "javascript": "javascript",
            "js": "javascript",
            "typescript": "typescript",
            "ts": "typescript",
            "html": "xml",
            "xml": "xml",
            "css": "css",
            "json": "json",
            "yaml": "yaml",
            "yml": "yaml",
            "markdown": "markdown",
            "md": "markdown",
            "sql": "sql",
            "go": "go",
            "rust": "rust",
            "ruby": "ruby",
            "java": "java",
            "kotlin": "kotlin",
            "c": "c",
            "cpp": "cpp",
            "c++": "cpp",
            "csharp": "csharp",
            "c#": "csharp",
            "php": "php",
            "r": "r",
            "dart": "dart",
            "elixir": "elixir",
            "perl": "perl",
            "scala": "scala",
            "haskell": "haskell"
        ]

        return languageMap[lang] ?? lang
    }
}

#Preview("Swift Code") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Light Mode").font(.headline)
        CodeHighlightView(
            code: """
            func greet(name: String) -> String {
                return "Hello, \\(name)!"
            }
            """,
            language: "swift"
        )
        .padding()
        .background(Color(nsColor: .textBackgroundColor))
    }
    .padding()
    .environment(\.colorScheme, .light)
}

#Preview("Python Code Dark") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Dark Mode").font(.headline).foregroundColor(.white)
        CodeHighlightView(
            code: """
            def greet(name):
                return f"Hello, {name}!"
            """,
            language: "python"
        )
        .padding()
        .background(Color(nsColor: .textBackgroundColor))
    }
    .padding()
    .environment(\.colorScheme, .dark)
}
