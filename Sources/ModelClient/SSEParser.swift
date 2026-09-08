import Foundation

public struct SSEEvent: Sendable, Equatable {
    public var event: String?
    public var data: String

    public init(event: String?, data: String) {
        self.event = event
        self.data = data
    }
}

/// Spec-lite assembler: join consecutive `data:` lines, ignore comments, dispatch on blank line.
public struct SSEAssembler: Sendable {
    public var eventName: String?
    public var dataLines: [String] = []

    public init() {}

    public mutating func push(_ line: String) -> SSEEvent? {
        if line.isEmpty {
            return flush()
        }
        if line.hasPrefix(":") { return nil }
        if line.hasPrefix("event:") {
            eventName = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            return nil
        }
        if line.hasPrefix("data:") {
            var value = String(line.dropFirst(5))
            if value.hasPrefix(" ") { value.removeFirst() }
            dataLines.append(value)
        }
        return nil
    }

    public mutating func finish() -> SSEEvent? {
        flush()
    }

    private mutating func flush() -> SSEEvent? {
        guard !dataLines.isEmpty else {
            eventName = nil
            return nil
        }
        let event = SSEEvent(event: eventName, data: dataLines.joined(separator: "\n"))
        eventName = nil
        dataLines = []
        return event
    }

    public static func parse(_ lines: [String]) -> [SSEEvent] {
        var assembler = SSEAssembler()
        var events: [SSEEvent] = []
        for line in lines {
            if let event = assembler.push(line) {
                events.append(event)
            }
        }
        if let event = assembler.finish() {
            events.append(event)
        }
        return events
    }
}

public enum SSEParser {
    public static func parse(_ lines: [String]) -> [SSEEvent] {
        SSEAssembler.parse(lines)
    }
}
