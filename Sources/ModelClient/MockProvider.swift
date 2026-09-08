import Foundation

/// Deterministic provider for tests and eval. Maps a ramble (or fixture id) to a canned JSON proposal.
public struct MockProvider: ModelProvider {
    public var responses: [String: String]
    public var defaultResponse: String
    public var streamedChunks: [String]

    public init(
        responses: [String: String] = [:],
        defaultResponse: String = "{\"events\":[],\"gaps\":[\"nothing to file\"]}",
        streamedChunks: [String] = []
    ) {
        self.responses = responses
        self.defaultResponse = defaultResponse
        self.streamedChunks = streamedChunks
    }

    public func complete(messages: [ChatMessage], jsonObject: Bool) async throws -> String {
        let last = messages.last(where: { $0.role == "user" })?.content ?? ""
        if let exact = responses[last] { return exact }
        for (key, value) in responses {
            if last.contains(key) { return value }
        }
        return defaultResponse
    }

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        let chunks = streamedChunks
        return AsyncThrowingStream { continuation in
            for chunk in chunks { continuation.yield(chunk) }
            continuation.finish()
        }
    }
}
