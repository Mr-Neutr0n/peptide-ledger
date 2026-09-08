import Testing
import Foundation
@testable import ModelClient

@Suite("ModelClient redaction, SSE, mock")
struct ModelClientTests {
    @Test("keys never survive redaction")
    func redaction() {
        let key = "sk-ant-secret-123456"
        let leaked = "Authorization: Bearer \(key) x-api-key: \(key)"
        let safe = Redaction.redact(leaked, secrets: [key])
        #expect(!safe.contains(key))
        #expect(safe.contains("<redacted-key>"))
        #expect(Redaction.containsSecret(leaked, secrets: [key]))
        #expect(!Redaction.containsSecret(safe, secrets: [key]))
    }

    @Test("empty key is refused before a request is built conceptually")
    func emptyKey() async {
        let provider = OpenAICompatibleProvider(
            config: .openaiCompatible(model: "gpt-4.1", apiKey: "")
        )
        await #expect(throws: ModelClientError.emptyKey) {
            _ = try await provider.complete(messages: [ChatMessage(role: "user", content: "hi")], jsonObject: false)
        }
    }

    @Test("MockProvider is deterministic")
    func mock() async throws {
        let mock = MockProvider(responses: ["hello": "{\"ok\":true}"], streamedChunks: ["a", "b"])
        let text = try await mock.complete(messages: [ChatMessage(role: "user", content: "hello")], jsonObject: true)
        #expect(text == "{\"ok\":true}")
        var chunks: [String] = []
        for try await chunk in mock.stream(messages: []) {
            chunks.append(chunk)
        }
        #expect(chunks == ["a", "b"])
    }

    @Test("SSE parser joins data lines and ignores comments")
    func sse() {
        let lines = [
            ": keep-alive",
            "event: content_block_delta",
            "data: {\"delta\":",
            "data: {\"text\":\"Hi\"}}",
            "",
            "data: [DONE]",
            "",
        ]
        let events = SSEParser.parse(lines)
        #expect(events.count == 2)
        #expect(events[0].event == "content_block_delta")
        #expect(events[0].data.contains("Hi"))
        #expect(events[1].data == "[DONE]")
    }
}
