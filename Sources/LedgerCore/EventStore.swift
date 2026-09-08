import Foundation

public actor EventStore {
    public let fileURL: URL
    private var events: [LedgerEvent]
    private let fileManager: FileManager

    public init(directory: URL, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("ledger.jsonl")
        if fileManager.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            self.events = try Self.decodeJSONL(data)
        } else {
            self.events = []
            fileManager.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        }
    }

    public func allEvents() -> [LedgerEvent] {
        events
    }

    /// Append-only. There is no update or delete.
    @discardableResult
    public func append(_ event: LedgerEvent) throws -> LedgerEvent {
        if events.contains(where: { $0.id == event.id }) {
            return event
        }
        var line = try LedgerJSON.encoder.encode(event)
        line.append(0x0A)
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } else {
            try line.write(to: fileURL)
        }
        events.append(event)
        return event
    }

    public func append(contentsOf newEvents: [LedgerEvent]) throws {
        for event in newEvents {
            try append(event)
        }
    }

    public func importJSONL(_ data: Data) throws -> Int {
        let incoming = try Self.decodeJSONL(data)
        var added = 0
        for event in incoming {
            let before = events.count
            try append(event)
            if events.count > before { added += 1 }
        }
        return added
    }

    public func jsonlData() throws -> Data {
        try Data(contentsOf: fileURL)
    }

    public func deleteEverything() throws {
        events = []
        try Data().write(to: fileURL)
    }

    public func projection() -> LedgerProjection {
        LedgerProjection.build(from: events)
    }

    static func decodeJSONL(_ data: Data) throws -> [LedgerEvent] {
        let text = String(decoding: data, as: UTF8.self)
        var result: [LedgerEvent] = []
        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            let row = try LedgerJSON.decoder.decode(LedgerEvent.self, from: Data(trimmed.utf8))
            result.append(row)
        }
        return result
    }
}
