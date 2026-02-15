import Foundation

actor OllamaService {
    static let shared = OllamaService()

    private var endpoint: String
    private var model: String
    private var isEnabled: Bool

    private init() {
        self.endpoint = UserDefaults.standard.string(forKey: "OllamaEndpoint") ?? "http://localhost:11434"
        self.model = UserDefaults.standard.string(forKey: "OllamaModel") ?? "nomic-embed-text"
        self.isEnabled = UserDefaults.standard.bool(forKey: "OllamaEnabled")
    }

    func configure(endpoint: String, model: String, isEnabled: Bool) {
        let normalizedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        self.endpoint = normalizedEndpoint
        self.model = model
        self.isEnabled = isEnabled

        UserDefaults.standard.set(normalizedEndpoint, forKey: "OllamaEndpoint")
        UserDefaults.standard.set(model, forKey: "OllamaModel")
        UserDefaults.standard.set(isEnabled, forKey: "OllamaEnabled")
    }

    func getConfiguration() -> (endpoint: String, model: String, isEnabled: Bool) {
        return (endpoint, model, isEnabled)
    }

    /// Generate embedding vector for text
    func embed(text: String) async throws -> [Double]? {
        guard isEnabled else {
            return nil
        }

        let url = try apiURL(path: "api/embeddings")

        let requestBody: [String: Any] = [
            "model": model,
            "prompt": text
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 10.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw OllamaError.httpError(statusCode: httpResponse.statusCode)
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let embedding = json["embedding"] as? [Double] else {
                throw OllamaError.invalidResponse
            }

            return embedding
        } catch let error as OllamaError {
            throw error
        } catch {
            // Connection failed, Ollama not running
            return nil
        }
    }

    /// Check if Ollama is available
    func checkAvailability() async -> Bool {
        guard isEnabled else {
            return false
        }

        guard let url = try? apiURL(path: "api/tags") else {
            return false
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Fetch available models from Ollama
    func fetchModels() async throws -> [String] {
        let url = try apiURL(path: "api/tags")

        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else {
            throw OllamaError.invalidResponse
        }

        return models.compactMap { $0["name"] as? String }
    }

    private func apiURL(path: String) throws -> URL {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmedEndpoint),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host != nil else {
            throw OllamaError.invalidEndpoint
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suffix = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, suffix].filter { !$0.isEmpty }.joined(separator: "/")
        components.query = nil
        components.fragment = nil

        guard let url = components.url else {
            throw OllamaError.invalidEndpoint
        }
        return url
    }

    /// Calculate cosine similarity between two vectors
    static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }
}

enum OllamaError: Error, LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case httpError(statusCode: Int)
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid Ollama endpoint URL"
        case .invalidResponse:
            return "Invalid response from Ollama"
        case .httpError(let code):
            return "Ollama HTTP error: \(code)"
        case .notAvailable:
            return "Ollama is not available"
        }
    }
}
