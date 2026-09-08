import Foundation

public struct SessionMessage: Sendable, Codable, Equatable, Identifiable {
    public var id: UUID
    public var parentId: UUID?
    public var role: String
    public var content: String
    public var createdAt: Date

    public init(id: UUID = UUID(), parentId: UUID? = nil, role: String, content: String, createdAt: Date = Date()) {
        self.id = id
        self.parentId = parentId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

/// Sessions are a JSONL tree (id, parentId), separate from the ledger.
public actor SessionStore {
    public let fileURL: URL
    private var messages: [SessionMessage]

    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("sessions.jsonl")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            self.messages = try Self.decode(data)
        } else {
            self.messages = []
            FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        }
    }

    public func all() -> [SessionMessage] { messages }

    public func append(_ message: SessionMessage) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var line = try encoder.encode(message)
        line.append(0x0A)
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        }
        messages.append(message)
    }

    public func lineage(of id: UUID) -> [SessionMessage] {
        let byId = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        var chain: [SessionMessage] = []
        var current = byId[id]
        while let node = current {
            chain.append(node)
            current = node.parentId.flatMap { byId[$0] }
        }
        return chain.reversed()
    }

    /// Compaction hook. Not implemented: returns the same messages and a note.
    public func compact(keepingLast n: Int) -> (kept: [SessionMessage], note: String) {
        let kept = Array(messages.suffix(n))
        return (kept, "compaction is stubbed; sessions stay as the full JSONL tree")
    }

    public func deleteEverything() throws {
        messages = []
        try Data().write(to: fileURL)
    }

    static func decode(_ data: Data) throws -> [SessionMessage] {
        let text = String(decoding: data, as: UTF8.self)
        var result: [SessionMessage] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            // SessionMessage uses default Date encoding; try ISO then default.
            if let row = try? decoder.decode(SessionMessage.self, from: Data(trimmed.utf8)) {
                result.append(row)
            } else {
                result.append(try JSONDecoder().decode(SessionMessage.self, from: Data(trimmed.utf8)))
            }
        }
        return result
    }
}
