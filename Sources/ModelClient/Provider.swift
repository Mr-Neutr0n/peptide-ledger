import Foundation

public struct ChatMessage: Sendable, Codable, Equatable {
    public var role: String
    public var content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct ProviderConfig: Sendable, Equatable {
    public var kind: ProviderKind
    public var model: String
    public var baseURL: URL
    public var apiKey: String

    public init(kind: ProviderKind, model: String, baseURL: URL, apiKey: String) {
        self.kind = kind
        self.model = model
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    public static func anthropic(model: String = "claude-sonnet-4-5", apiKey: String) -> ProviderConfig {
        ProviderConfig(
            kind: .anthropic,
            model: model,
            baseURL: URL(string: "https://api.anthropic.com")!,
            apiKey: apiKey
        )
    }

    public static func openaiCompatible(
        model: String,
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        apiKey: String
    ) -> ProviderConfig {
        ProviderConfig(kind: .openaiCompatible, model: model, baseURL: baseURL, apiKey: apiKey)
    }
}

public enum ProviderKind: String, Sendable, Codable, CaseIterable {
    case anthropic
    case openaiCompatible
}

public protocol ModelProvider: Sendable {
    func complete(messages: [ChatMessage], jsonObject: Bool) async throws -> String
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

public enum ModelClientError: Error, Sendable, Equatable {
    case emptyKey
    case httpStatus(Int, String)
    case decoding(String)
    case emptyResponse
}

