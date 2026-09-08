import Foundation
import DoseMath
import LedgerCore

public enum ProposalParser {
    public static func parse(_ json: String) throws -> Proposal {
        let trimmed = stripFence(json)
        guard let data = trimmed.data(using: .utf8) else {
            return Proposal(events: [], gaps: ["model output was not UTF-8"])
        }
        if let direct = try? JSONDecoder().decode(LooseProposal.self, from: data) {
            return direct.materialize()
        }
        // Sometimes the model wraps the object.
        if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let inner = obj["proposal"] ?? obj["result"] ?? obj
            let innerData = try JSONSerialization.data(withJSONObject: inner)
            let loose = try JSONDecoder().decode(LooseProposal.self, from: innerData)
            return loose.materialize()
        }
        return Proposal(events: [], gaps: ["could not parse model JSON"])
    }

    static func stripFence(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            }
            if text.hasSuffix("```") {
                text.removeLast(3)
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct LooseProposal: Decodable {
    var events: [LooseEvent]?
    var gaps: [String]?

    func materialize() -> Proposal {
        let events = (events ?? []).compactMap { $0.materialize() }
        return Proposal(events: events, gaps: gaps ?? [])
    }
}

struct LooseEvent: Decodable {
    var kind: String?
    var excerpt: String?
    var occurredAt: String?
    var payload: LoosePayload?

    func materialize() -> ProposedEvent? {
        guard let kindRaw = kind, let kind = LedgerEventKind(rawValue: kindRaw) else { return nil }
        let date = occurredAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        let payload = payload?.materialize(kind: kind) ?? defaultPayload(kind)
        return ProposedEvent(kind: kind, payload: payload, excerpt: excerpt, occurredAt: date)
    }

    func defaultPayload(_ kind: LedgerEventKind) -> EventPayload {
        switch kind {
        case .noteAdded: return .noteAdded(NoteAddedPayload(text: excerpt ?? ""))
        case .symptomLogged: return .symptomLogged(SymptomLoggedPayload(text: excerpt ?? ""))
        default: return .noteAdded(NoteAddedPayload(text: excerpt ?? kind.rawValue))
        }
    }
}

struct LoosePayload: Decodable {
    var vialId: UUID?
    var compoundName: String?
    var doseMass: LooseMass?
    var doseIU: LooseIU?
    var drawVolume: LooseVolume?
    var syringeScale: String?
    var syringeUnits: Decimal?
    var site: String?
    var notes: String?
    var labeledMass: LooseMass?
    var labeledVolume: LooseVolume?
    var lot: String?
    var expiry: String?
    var photoRelativePath: String?
    var storageNote: String?
    var diluentVolume: LooseVolume?
    var diluentName: String?
    var reason: String?
    var text: String?
    var severity: String?
    var kilograms: Decimal?
    var pounds: Decimal?
    var supersedes: UUID?

    func materialize(kind: LedgerEventKind) -> EventPayload {
        switch kind {
        case .doseLogged:
            return .doseLogged(DoseLoggedPayload(
                vialId: vialId,
                compoundName: compoundName ?? "unknown",
                doseMass: doseMass?.mass,
                doseIU: doseIU?.iu,
                drawVolume: drawVolume?.volume,
                syringeScale: syringeScale.flatMap(SyringeScale.init(rawValue:)),
                syringeUnits: syringeUnits,
                site: site,
                notes: notes
            ))
        case .vialAdded:
            return .vialAdded(VialAddedPayload(
                vialId: vialId ?? UUID(),
                compoundName: compoundName ?? "unknown",
                labeledMass: labeledMass?.mass,
                labeledVolume: labeledVolume?.volume,
                lot: lot,
                expiry: expiry,
                photoRelativePath: photoRelativePath,
                storageNote: storageNote
            ))
        case .vialReconstituted:
            return .vialReconstituted(VialReconstitutedPayload(
                vialId: vialId ?? UUID(),
                diluentVolume: diluentVolume?.volume ?? Volume(milliliters: 0),
                diluentName: diluentName,
                labeledMass: labeledMass?.mass
            ))
        case .vialDiscarded:
            return .vialDiscarded(VialDiscardedPayload(vialId: vialId ?? UUID(), reason: reason))
        case .symptomLogged:
            return .symptomLogged(SymptomLoggedPayload(text: text ?? notes ?? "", severity: severity))
        case .weightLogged:
            return .weightLogged(WeightLoggedPayload(kilograms: kilograms, pounds: pounds))
        case .noteAdded:
            return .noteAdded(NoteAddedPayload(text: text ?? notes ?? ""))
        case .eventSuperseded:
            return .eventSuperseded(EventSupersededPayload(supersedes: supersedes ?? UUID(), reason: reason))
        }
    }
}

struct LooseMass: Decodable {
    var value: Decimal
    var unit: String
    var mass: Mass {
        let unit = MassUnit(rawValue: unit) ?? (unit == "ug" || unit == "µg" ? .microgram : .milligram)
        return Mass(value, unit)
    }
}

struct LooseIU: Decodable {
    var value: Decimal
    var iu: InternationalUnits { InternationalUnits(value) }
}

struct LooseVolume: Decodable {
    var milliliters: Decimal
    var volume: Volume { Volume(milliliters: milliliters) }
}
