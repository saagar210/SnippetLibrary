import XCTest
@testable import SnippetLibrary

final class OllamaServiceTests: XCTestCase {
    private var originalConfig: (endpoint: String, model: String, isEnabled: Bool)?

    override func setUp() async throws {
        originalConfig = await OllamaService.shared.getConfiguration()
    }

    override func tearDown() async throws {
        if let config = originalConfig {
            await OllamaService.shared.configure(endpoint: config.endpoint, model: config.model, isEnabled: config.isEnabled)
        }
    }

    func testEmbedThrowsInvalidEndpoint() async {
        await OllamaService.shared.configure(endpoint: "not a valid url", model: "nomic-embed-text", isEnabled: true)

        do {
            _ = try await OllamaService.shared.embed(text: "hello")
            XCTFail("Expected invalidEndpoint error")
        } catch OllamaError.invalidEndpoint {
            // expected
        } catch {
            XCTFail("Expected invalidEndpoint, got \(error)")
        }
    }

    func testAvailabilityReturnsFalseForInvalidEndpoint() async {
        await OllamaService.shared.configure(endpoint: "invalid://", model: "nomic-embed-text", isEnabled: true)

        let isAvailable = await OllamaService.shared.checkAvailability()
        XCTAssertFalse(isAvailable)
    }

    func testConfigureTrimsEndpointWhitespace() async {
        await OllamaService.shared.configure(endpoint: "  http://localhost:11434/  ", model: "nomic-embed-text", isEnabled: true)

        let config = await OllamaService.shared.getConfiguration()
        XCTAssertEqual(config.endpoint, "http://localhost:11434/")
    }
}
