import Foundation

public enum LedgerExport {
    public static func csv(from events: [LedgerEvent]) -> String {
        var rows: [String] = ["id,occurredAt,recordedAt,kind,excerpt,detail"]
        let iso = ISO8601DateFormatter()
        for event in events {
            let excerpt = csvEscape(event.excerpt ?? "")
            let detail = csvEscape(detailString(event.payload))
            rows.append([
                event.id.uuidString,
                iso.string(from: event.occurredAt),
                iso.string(from: event.recordedAt),
                event.kind.rawValue,
                excerpt,
                detail,
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    public static func jsonl(from events: [LedgerEvent]) throws -> Data {
        var data = Data()
        for event in events {
            var line = try LedgerJSON.encoder.encode(event)
            line.append(0x0A)
            data.append(line)
        }
        return data
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(where: { ",\"\n".contains($0) }) {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func detailString(_ payload: EventPayload) -> String {
        switch payload {
        case .doseLogged(let p):
            return "compound=\(p.compoundName) dose=\(p.doseMass?.description ?? p.doseIU?.description ?? "") site=\(p.site ?? "")"
        case .vialAdded(let p):
            return "compound=\(p.compoundName) mass=\(p.labeledMass?.description ?? "") lot=\(p.lot ?? "")"
        case .vialReconstituted(let p):
            return "vial=\(p.vialId) diluent=\(p.diluentVolume)"
        case .vialDiscarded(let p):
            return "vial=\(p.vialId) reason=\(p.reason ?? "")"
        case .symptomLogged(let p):
            return p.text
        case .weightLogged(let p):
            if let kg = p.kilograms { return "\(kg) kg" }
            if let lb = p.pounds { return "\(lb) lb" }
            return ""
        case .noteAdded(let p):
            return p.text
        case .eventSuperseded(let p):
            return "supersedes=\(p.supersedes) reason=\(p.reason ?? "")"
        }
    }
}
