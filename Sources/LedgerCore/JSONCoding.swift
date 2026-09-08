import Foundation

enum LedgerJSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension EventPayload {
    private enum CodingKeys: String, CodingKey {
        case type
        case doseLogged, vialAdded, vialReconstituted, vialDiscarded
        case symptomLogged, weightLogged, noteAdded, eventSuperseded
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(LedgerEventKind.self, forKey: .type)
        switch type {
        case .doseLogged:
            self = .doseLogged(try container.decode(DoseLoggedPayload.self, forKey: .doseLogged))
        case .vialAdded:
            self = .vialAdded(try container.decode(VialAddedPayload.self, forKey: .vialAdded))
        case .vialReconstituted:
            self = .vialReconstituted(try container.decode(VialReconstitutedPayload.self, forKey: .vialReconstituted))
        case .vialDiscarded:
            self = .vialDiscarded(try container.decode(VialDiscardedPayload.self, forKey: .vialDiscarded))
        case .symptomLogged:
            self = .symptomLogged(try container.decode(SymptomLoggedPayload.self, forKey: .symptomLogged))
        case .weightLogged:
            self = .weightLogged(try container.decode(WeightLoggedPayload.self, forKey: .weightLogged))
        case .noteAdded:
            self = .noteAdded(try container.decode(NoteAddedPayload.self, forKey: .noteAdded))
        case .eventSuperseded:
            self = .eventSuperseded(try container.decode(EventSupersededPayload.self, forKey: .eventSuperseded))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .doseLogged(let payload):
            try container.encode(LedgerEventKind.doseLogged, forKey: .type)
            try container.encode(payload, forKey: .doseLogged)
        case .vialAdded(let payload):
            try container.encode(LedgerEventKind.vialAdded, forKey: .type)
            try container.encode(payload, forKey: .vialAdded)
        case .vialReconstituted(let payload):
            try container.encode(LedgerEventKind.vialReconstituted, forKey: .type)
            try container.encode(payload, forKey: .vialReconstituted)
        case .vialDiscarded(let payload):
            try container.encode(LedgerEventKind.vialDiscarded, forKey: .type)
            try container.encode(payload, forKey: .vialDiscarded)
        case .symptomLogged(let payload):
            try container.encode(LedgerEventKind.symptomLogged, forKey: .type)
            try container.encode(payload, forKey: .symptomLogged)
        case .weightLogged(let payload):
            try container.encode(LedgerEventKind.weightLogged, forKey: .type)
            try container.encode(payload, forKey: .weightLogged)
        case .noteAdded(let payload):
            try container.encode(LedgerEventKind.noteAdded, forKey: .type)
            try container.encode(payload, forKey: .noteAdded)
        case .eventSuperseded(let payload):
            try container.encode(LedgerEventKind.eventSuperseded, forKey: .type)
            try container.encode(payload, forKey: .eventSuperseded)
        }
    }
}
