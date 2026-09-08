import Foundation

public struct AnthropicProvider: ModelProvider {
    public var config: ProviderConfig
    public var session: URLSession
    private var log: RedactingLog

    public init(config: ProviderConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        self.log = RedactingLog(secrets: [config.apiKey])
    }

    public func complete(messages: [ChatMessage], jsonObject: Bool) async throws -> String {
        if config.apiKey.isEmpty { throw ModelClientError.emptyKey }
        var request = URLRequest(url: config.baseURL.appendingPathComponent("v1/messages"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        let (system, userMessages) = Self.splitSystem(messages)
        var body: [String: Any] = [
            "model": config.model,
            "max_tokens": 4096,
            "messages": userMessages.map { ["role": $0.role, "content": $0.content] },
        ]
        if let system { body["system"] = system }
        if jsonObject {
            body["output_config"] = ["format"] // keep body JSON; actual schema is applied by Clerk via instruction
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        log.info("POST \(request.url?.absoluteString ?? "") model=\(config.model)")
        let (data, response) = try await session.data(for: request)
        try Self.throwIfNeeded(data: data, response: response, secret: config.apiKey)
        return try Self.extractText(from: data)
    }

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    if config.apiKey.isEmpty { throw ModelClientError.emptyKey }
                    var request = URLRequest(url: config.baseURL.appendingPathComponent("v1/messages"))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    let (system, userMessages) = Self.splitSystem(messages)
                    var body: [String: Any] = [
                        "model": config.model,
                        "max_tokens": 4096,
                        "stream": true,
                        "messages": userMessages.map { ["role": $0.role, "content": $0.content] },
                    ]
                    if let system { body["system"] = system }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (bytes, response) = try await session.bytes(for: request)
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        throw ModelClientError.httpStatus(http.statusCode, "<redacted>")
                    }
                    var assembler = SSEAssembler()
                    for try await line in bytes.lines {
                        if let event = assembler.push(line) {
                            if event.data == "[DONE]" { continue }
                            guard let data = event.data.data(using: .utf8),
                                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                            else { continue }
                            if let delta = obj["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                continuation.yield(text)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func splitSystem(_ messages: [ChatMessage]) -> (String?, [ChatMessage]) {
        let system = messages.filter { $0.role == "system" }.map(\.content).joined(separator: "\n\n")
        let rest = messages.filter { $0.role != "system" }
        return (system.isEmpty ? nil : system, rest)
    }

    static func throwIfNeeded(data: Data, response: URLResponse, secret: String) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if (200..<300).contains(http.statusCode) { return }
        let raw = String(decoding: data, as: UTF8.self)
        throw ModelClientError.httpStatus(http.statusCode, Redaction.redact(raw, secrets: [secret]))
    }

    static func extractText(from data: Data) throws -> String {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = obj["content"] as? [[String: Any]]
        else { throw ModelClientError.decoding("anthropic content") }
        let text = content.compactMap { $0["text"] as? String }.joined()
        if text.isEmpty { throw ModelClientError.emptyResponse }
        return text
    }
}

public struct OpenAICompatibleProvider: ModelProvider {
    public var config: ProviderConfig
    public var session: URLSession
    private var log: RedactingLog

    public init(config: ProviderConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        self.log = RedactingLog(secrets: [config.apiKey])
    }

    public func complete(messages: [ChatMessage], jsonObject: Bool) async throws -> String {
        if config.apiKey.isEmpty { throw ModelClientError.emptyKey }
        var request = URLRequest(url: config.baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        var body: [String: Any] = [
            "model": config.model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
        ]
        if jsonObject {
            body["response_format"] = ["type": "json_object"]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        log.info("POST \(request.url?.absoluteString ?? "") model=\(config.model)")
        let (data, response) = try await session.data(for: request)
        try AnthropicProvider.throwIfNeeded(data: data, response: response, secret: config.apiKey)
        return try Self.extractText(from: data)
    }

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    if config.apiKey.isEmpty { throw ModelClientError.emptyKey }
                    var request = URLRequest(url: config.baseURL.appendingPathComponent("chat/completions"))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
                    let body: [String: Any] = [
                        "model": config.model,
                        "stream": true,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (bytes, response) = try await session.bytes(for: request)
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        throw ModelClientError.httpStatus(http.statusCode, "<redacted>")
                    }
                    var assembler = SSEAssembler()
                    for try await line in bytes.lines {
                        if let event = assembler.push(line) {
                            if event.data == "[DONE]" { continue }
                            guard let data = event.data.data(using: .utf8),
                                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                  let choices = obj["choices"] as? [[String: Any]],
                                  let delta = choices.first?["delta"] as? [String: Any],
                                  let text = delta["content"] as? String
                            else { continue }
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func extractText(from data: Data) throws -> String {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String, !text.isEmpty
        else { throw ModelClientError.decoding("openai content") }
        return text
    }
}
