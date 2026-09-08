import Foundation

public struct LabelCandidate: Sendable, Equatable, Codable {
    public var compoundName: String?
    public var massText: String?
    public var massValue: Decimal?
    public var massUnit: String?
    public var lot: String?
    public var expiry: String?
    public var rawText: String
    public var confidence: Double

    public init(
        compoundName: String? = nil,
        massText: String? = nil,
        massValue: Decimal? = nil,
        massUnit: String? = nil,
        lot: String? = nil,
        expiry: String? = nil,
        rawText: String,
        confidence: Double
    ) {
        self.compoundName = compoundName
        self.massText = massText
        self.massValue = massValue
        self.massUnit = massUnit
        self.lot = lot
        self.expiry = expiry
        self.rawText = rawText
        self.confidence = confidence
    }
}

/// Turns recognized label text into candidate fields. Never commits a ledger row.
public enum LabelFieldParser {
    public static func parse(_ text: String) -> LabelCandidate {
        let lines = text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var compound: String?
        var massText: String?
        var massValue: Decimal?
        var massUnit: String?
        var lot: String?
        var expiry: String?
        var hits = 0

        let massRegex = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*(mg|mcg|µg|ug|iu)\b"#, options: .caseInsensitive)
        let lotRegex = try! NSRegularExpression(pattern: #"\b(?:lot|batch)[:\s#-]*([A-Z0-9\-]+)"#, options: .caseInsensitive)
        let expiryRegex = try! NSRegularExpression(
            pattern: #"\b(?:exp(?:iry|ires)?|use by|bud)[:\s]*([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4}|[0-9]{1,2}[/-][0-9]{2,4}|[A-Z]{3}[a-z]*\s*[0-9]{4})"#,
            options: .caseInsensitive
        )

        for line in lines {
            let ns = line as NSString
            let range = NSRange(location: 0, length: ns.length)
            if massText == nil, let match = massRegex.firstMatch(in: line, range: range) {
                massValue = Decimal(string: ns.substring(with: match.range(at: 1)))
                var unit = ns.substring(with: match.range(at: 2)).lowercased()
                if unit == "µg" || unit == "ug" { unit = "mcg" }
                massUnit = unit
                massText = "\(ns.substring(with: match.range(at: 1))) \(unit)"
                hits += 1
                let before = ns.substring(to: match.range(at: 1).location)
                    .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                if compound == nil, before.count >= 3 {
                    compound = before
                    hits += 1
                }
            }
            if lot == nil, let match = lotRegex.firstMatch(in: line, range: range) {
                lot = ns.substring(with: match.range(at: 1))
                hits += 1
            }
            if expiry == nil, let match = expiryRegex.firstMatch(in: line, range: range) {
                expiry = ns.substring(with: match.range(at: 1))
                hits += 1
            }
        }

        let skip = ["lot", "batch", "exp", "expiry", "lyophilized", "research", "not for", "sterile", "inject"]
        if compound == nil {
            compound = lines.first { line in
                let lower = line.lowercased()
                let range = NSRange(location: 0, length: (line as NSString).length)
                if massRegex.firstMatch(in: line, range: range) != nil {
                    return false
                }
                return !skip.contains { lower.contains($0) } && line.count >= 3
            }
            if compound != nil { hits += 1 }
        }

        let confidence = min(0.95, 0.2 * Double(hits))
        return LabelCandidate(
            compoundName: compound,
            massText: massText,
            massValue: massValue,
            massUnit: massUnit,
            lot: lot,
            expiry: expiry,
            rawText: text,
            confidence: confidence
        )
    }
}
