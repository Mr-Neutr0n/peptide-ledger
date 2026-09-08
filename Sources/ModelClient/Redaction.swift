import Foundation

public enum Redaction: Sendable {
    /// Replace any supplied secrets in a string so logs never contain a key.
    public static func redact(_ text: String, secrets: [String]) -> String {
        secrets.reduce(text) { partial, secret in
            guard !secret.isEmpty else { return partial }
            return partial.replacingOccurrences(of: secret, with: "<redacted-key>")
        }
    }

    public static func containsSecret(_ text: String, secrets: [String]) -> Bool {
        secrets.contains { !$0.isEmpty && text.contains($0) }
    }
}

public struct RedactingLog: Sendable {
    private let secrets: [String]
    private let sink: @Sendable (String) -> Void

    public init(secrets: [String], sink: @escaping @Sendable (String) -> Void = { _ in }) {
        self.secrets = secrets
        self.sink = sink
    }

    public func info(_ message: String) {
        let safe = Redaction.redact(message, secrets: secrets)
        sink(safe)
    }
}
