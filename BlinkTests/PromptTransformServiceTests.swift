import XCTest
@testable import Blink

final class PromptTransformServiceTests: XCTestCase {
    func testChatCompletionsURLFromBase() {
        let url = PromptTransformService.chatCompletionsURL(from: "https://api.openai.com/v1")
        XCTAssertEqual(url?.absoluteString, "https://api.openai.com/v1/chat/completions")
    }

    func testChatCompletionsURLFromFullPath() {
        let url = PromptTransformService.chatCompletionsURL(
            from: "https://api.openai.com/v1/chat/completions"
        )
        XCTAssertEqual(url?.absoluteString, "https://api.openai.com/v1/chat/completions")
    }

    func testChatCompletionsURLTrimsTrailingSlash() {
        let url = PromptTransformService.chatCompletionsURL(from: "https://example.com/v1/")
        XCTAssertEqual(url?.absoluteString, "https://example.com/v1/chat/completions")
    }

    func testChatCompletionsURLRejectsEmpty() {
        XCTAssertNil(PromptTransformService.chatCompletionsURL(from: "   "))
    }

    func testChatCompletionsURLForOllamaOpenAICompat() {
        let url = PromptTransformService.chatCompletionsURL(from: OllamaClient.defaultOpenAIEndpoint)
        XCTAssertEqual(url?.absoluteString, "http://localhost:11434/v1/chat/completions")
    }
}
