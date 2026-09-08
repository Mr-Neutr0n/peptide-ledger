import Foundation
import DoseMath

public enum LedgerEventKind: String, Sendable, Codable, CaseIterable {
    case doseLogged
    case vialAdded
    case vialReconstituted
    case vialDiscarded
    case symptomLogged
    case weightLogged
    case noteAdded
    case eventSuperseded
}

public struct LedgerEvent: Sendable, Codable, Equatable, Identifiable {
    public var id: UUID
    public var occurredAt: Date
    public var recordedAt: Date
    public var kind: LedgerEventKind
    public var payload: EventPayload
    /// Optional excerpt from the ramble that produced this row, kept for audit.
    public var excerpt: String?

    public init(
        id: UUID = UUID(),
        occurredAt: Date,
        recordedAt: Date = Date(),
        kind: LedgerEventKind,
        payload: EventPayload,
        excerpt: String? = nil
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.recordedAt = recordedAt
        self.kind = kind
        self.payload = payload
        self.excerpt = excerpt
    }
}

public enum EventPayload: Sendable, Codable, Equatable {
    case doseLogged(DoseLoggedPayload)
    case vialAdded(VialAddedPayload)
    case vialReconstituted(VialReconstitutedPayload)
    case vialDiscarded(VialDiscardedPayload)
    case symptomLogged(SymptomLoggedPayload)
    case weightLogged(WeightLoggedPayload)
    case noteAdded(NoteAddedPayload)
    case eventSuperseded(EventSupersededPayload)
}

public struct DoseLoggedPayload: Sendable, Codable, Equatable {
    public var vialId: UUID?
    public var compoundName: String
    public var doseMass: Mass?
    public var doseIU: InternationalUnits?
    public var drawVolume: Volume?
    public var syringeScale: SyringeScale?
    public var syringeUnits: Decimal?
    public var site: String?
    public var notes: String?

    public init(
        vialId: UUID? = nil,
        compoundName: String,
        doseMass: Mass? = nil,
        doseIU: InternationalUnits? = nil,
        drawVolume: Volume? = nil,
        syringeScale: SyringeScale? = nil,
        syringeUnits: Decimal? = nil,
        site: String? = nil,
        notes: String? = nil
    ) {
        self.vialId = vialId
        self.compoundName = compoundName
        self.doseMass = doseMass
        self.doseIU = doseIU
        self.drawVolume = drawVolume
        self.syringeScale = syringeScale
        self.syringeUnits = syringeUnits
        self.site = site
        self.notes = notes
    }
}

public struct VialAddedPayload: Sendable, Codable, Equatable {
    public var vialId: UUID
    public var compoundName: String
    public var labeledMass: Mass?
    public var labeledVolume: Volume?
    public var lot: String?
    public var expiry: String?
    public var photoRelativePath: String?
    public var storageNote: String?

    public init(
        vialId: UUID = UUID(),
        compoundName: String,
        labeledMass: Mass? = nil,
        labeledVolume: Volume? = nil,
        lot: String? = nil,
        expiry: String? = nil,
        photoRelativePath: String? = nil,
        storageNote: String? = nil
    ) {
        self.vialId = vialId
        self.compoundName = compoundName
        self.labeledMass = labeledMass
        self.labeledVolume = labeledVolume
        self.lot = lot
        self.expiry = expiry
        self.photoRelativePath = photoRelativePath
        self.storageNote = storageNote
    }
}

public struct VialReconstitutedPayload: Sendable, Codable, Equatable {
    public var vialId: UUID
    public var diluentVolume: Volume
    public var diluentName: String?
    public var labeledMass: Mass?

    public init(vialId: UUID, diluentVolume: Volume, diluentName: String? = nil, labeledMass: Mass? = nil) {
        self.vialId = vialId
        self.diluentVolume = diluentVolume
        self.diluentName = diluentName
        self.labeledMass = labeledMass
    }
}

public struct VialDiscardedPayload: Sendable, Codable, Equatable {
    public var vialId: UUID
    public var reason: String?

    public init(vialId: UUID, reason: String? = nil) {
        self.vialId = vialId
        self.reason = reason
    }
}

public struct SymptomLoggedPayload: Sendable, Codable, Equatable {
    public var text: String
    public var severity: String?

    public init(text: String, severity: String? = nil) {
        self.text = text
        self.severity = severity
    }
}

public struct WeightLoggedPayload: Sendable, Codable, Equatable {
    public var kilograms: Decimal?
    public var pounds: Decimal?

    public init(kilograms: Decimal? = nil, pounds: Decimal? = nil) {
        self.kilograms = kilograms
        self.pounds = pounds
    }
}

public struct NoteAddedPayload: Sendable, Codable, Equatable {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public struct EventSupersededPayload: Sendable, Codable, Equatable {
    public var supersedes: UUID
    public var reason: String?

    public init(supersedes: UUID, reason: String? = nil) {
        self.supersedes = supersedes
        self.reason = reason
    }
}

public struct ProposedEvent: Sendable, Codable, Equatable {
    public var kind: LedgerEventKind
    public var payload: EventPayload
    public var excerpt: String?
    public var occurredAt: Date?

    public init(kind: LedgerEventKind, payload: EventPayload, excerpt: String? = nil, occurredAt: Date? = nil) {
        self.kind = kind
        self.payload = payload
        self.excerpt = excerpt
        self.occurredAt = occurredAt
    }
}

public struct Proposal: Sendable, Codable, Equatable {
    public var events: [ProposedEvent]
    public var gaps: [String]

    public init(events: [ProposedEvent] = [], gaps: [String] = []) {
        self.events = events
        self.gaps = gaps
    }
}
