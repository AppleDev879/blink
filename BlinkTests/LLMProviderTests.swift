import XCTest
@testable import Blink

final class LLMProviderTests: XCTestCase {
    func testParseKnownValues() {
        XCTAssertEqual(LLMProvider.parse("off"), .off)
        XCTAssertEqual(LLMProvider.parse("BYOK"), .byok)
        XCTAssertEqual(LLMProvider.parse(" local "), .local)
    }

    func testParseRejectsUnknown() {
        XCTAssertNil(LLMProvider.parse("hosted"))
        XCTAssertNil(LLMProvider.parse(nil))
        XCTAssertNil(LLMProvider.parse(""))
    }

    func testTransformsEnabled() {
        XCTAssertFalse(LLMProvider.off.transformsEnabled)
        XCTAssertTrue(LLMProvider.byok.transformsEnabled)
        XCTAssertTrue(LLMProvider.local.transformsEnabled)
    }
}

final class OllamaClientURLTests: XCTestCase {
    func testNativeBaseStripsV1() {
        XCTAssertEqual(
            OllamaClient.nativeBaseURL(from: "http://localhost:11434/v1"),
            "http://localhost:11434"
        )
        XCTAssertEqual(
            OllamaClient.nativeBaseURL(from: "http://localhost:11434/v1/"),
            "http://localhost:11434"
        )
    }

    func testNativeBaseDefaultWhenEmpty() {
        XCTAssertEqual(OllamaClient.nativeBaseURL(from: "  "), OllamaClient.defaultBaseURL)
    }

    func testOpenAIEndpointAppendsV1() {
        XCTAssertEqual(
            OllamaClient.openAIEndpoint(fromNativeBase: "http://localhost:11434"),
            "http://localhost:11434/v1"
        )
        XCTAssertEqual(
            OllamaClient.openAIEndpoint(fromNativeBase: "http://localhost:11434/v1"),
            "http://localhost:11434/v1"
        )
    }

    func testTagsURL() {
        XCTAssertEqual(
            OllamaClient.tagsURL(from: "http://localhost:11434/v1")?.absoluteString,
            "http://localhost:11434/api/tags"
        )
    }

    func testLooksLikeLocalEndpoint() {
        XCTAssertTrue(OllamaClient.looksLikeLocalEndpoint("http://localhost:11434/v1"))
        XCTAssertTrue(OllamaClient.looksLikeLocalEndpoint("http://127.0.0.1:11434"))
        XCTAssertFalse(OllamaClient.looksLikeLocalEndpoint("https://api.openai.com/v1"))
    }

    func testParseModelNames() throws {
        let json = """
        {"models":[{"name":"llama3.2:latest"},{"name":"mistral"},{"name":"  "}]}
        """.data(using: .utf8)!
        XCTAssertEqual(OllamaClient.parseModelNames(from: json), ["llama3.2:latest", "mistral"])
    }

    func testDefaultConstants() {
        XCTAssertEqual(OllamaClient.defaultBaseURL, "http://localhost:11434")
        XCTAssertEqual(OllamaClient.defaultOpenAIEndpoint, "http://localhost:11434/v1")
    }
}

@MainActor
final class PromptTransformSettingsProviderTests: XCTestCase {
    func testMigratesEnabledTrueToBYOK() {
        let suite = "blink.tests.provider.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "blink.promptTransform.enabled")

        let settings = PromptTransformSettings(defaults: defaults)
        XCTAssertEqual(settings.provider, .byok)
        XCTAssertTrue(settings.isEnabled)
    }

    func testMigratesEnabledFalseToOff() {
        let suite = "blink.tests.provider.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "blink.promptTransform.enabled")

        let settings = PromptTransformSettings(defaults: defaults)
        XCTAssertEqual(settings.provider, .off)
        XCTAssertFalse(settings.isEnabled)
    }

    func testPersistsProviderRawValue() {
        let suite = "blink.tests.provider.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let settings = PromptTransformSettings(defaults: defaults)
        settings.provider = .local
        XCTAssertEqual(defaults.string(forKey: "blink.promptTransform.provider"), "local")
        XCTAssertEqual(settings.endpoint, OllamaClient.defaultOpenAIEndpoint)
    }

    func testUseLocalModelSetsProviderAndEndpoint() {
        let suite = "blink.tests.provider.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let settings = PromptTransformSettings(defaults: defaults)
        settings.localModels = ["phi3:latest", "llama3.2"]
        settings.useLocalModel()
        XCTAssertEqual(settings.provider, .local)
        XCTAssertEqual(settings.endpoint, OllamaClient.defaultOpenAIEndpoint)
        XCTAssertEqual(settings.model, "phi3:latest")
        XCTAssertEqual(settings.localReachable, true)
    }
}
