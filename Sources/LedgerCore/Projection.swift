import Foundation
import DoseMath

public struct VialState: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var compoundName: String
    public var labeledMass: Mass?
    public var labeledVolume: Volume?
    public var lot: String?
    public var expiry: String?
    public var photoRelativePath: String?
    public var storageNote: String?
    public var diluentVolume: Volume?
    public var diluentName: String?
    public var mixedAt: Date?
    public var discarded: Bool
    public var drawnVolume: Volume
    public var addedAt: Date

    public var remainingVolume: Volume? {
        guard let start = diluentVolume ?? labeledVolume else { return nil }
        return RemainingDoses.remainingVolume(start: start, drawn: drawnVolume)
    }

    public var concentration: Concentration? {
        guard let mass = labeledMass, let per = diluentVolume ?? labeledVolume else { return nil }
        return try? Concentration.reconstitute(mass: mass, diluent: per)
    }
}

public struct LedgerProjection: Sendable, Equatable {
    public var vials: [VialState]
    public var doses: [LedgerEvent]
    public var symptoms: [LedgerEvent]
    public var weights: [LedgerEvent]
    public var notes: [LedgerEvent]
    public var sites: [String]
    public var supersededIds: Set<UUID>

    public var currentVials: [VialState] { vials.filter { !$0.discarded } }

    public static func build(from events: [LedgerEvent]) -> LedgerProjection {
        let superseded = Set(events.compactMap { event -> UUID? in
            if case .eventSuperseded(let payload) = event.payload {
                return payload.supersedes
            }
            return nil
        })
        let live = events.filter { !superseded.contains($0.id) && $0.kind != .eventSuperseded }

        var vials: [UUID: VialState] = [:]
        var doses: [LedgerEvent] = []
        var symptoms: [LedgerEvent] = []
        var weights: [LedgerEvent] = []
        var notes: [LedgerEvent] = []
        var sites: [String] = []

        for event in live.sorted(by: { $0.occurredAt < $1.occurredAt }) {
            switch event.payload {
            case .vialAdded(let payload):
                vials[payload.vialId] = VialState(
                    id: payload.vialId,
                    compoundName: payload.compoundName,
                    labeledMass: payload.labeledMass,
                    labeledVolume: payload.labeledVolume,
                    lot: payload.lot,
                    expiry: payload.expiry,
                    photoRelativePath: payload.photoRelativePath,
                    storageNote: payload.storageNote,
                    diluentVolume: payload.labeledVolume,
                    diluentName: nil,
                    mixedAt: nil,
                    discarded: false,
                    drawnVolume: Volume(milliliters: 0),
                    addedAt: event.occurredAt
                )
            case .vialReconstituted(let payload):
                if var vial = vials[payload.vialId] {
                    vial.diluentVolume = payload.diluentVolume
                    vial.diluentName = payload.diluentName
                    if let mass = payload.labeledMass {
                        vial.labeledMass = mass
                    }
                    vial.mixedAt = event.occurredAt
                    vials[payload.vialId] = vial
                }
            case .vialDiscarded(let payload):
                if var vial = vials[payload.vialId] {
                    vial.discarded = true
                    vials[payload.vialId] = vial
                }
            case .doseLogged(let payload):
                doses.append(event)
                if let site = payload.site, !site.isEmpty {
                    sites.append(site)
                }
                if let vialId = payload.vialId, var vial = vials[vialId], let draw = payload.drawVolume {
                    vial.drawnVolume = Volume(milliliters: vial.drawnVolume.milliliters + draw.milliliters)
                    vials[vialId] = vial
                }
            case .symptomLogged:
                symptoms.append(event)
            case .weightLogged:
                weights.append(event)
            case .noteAdded:
                notes.append(event)
            case .eventSuperseded:
                break
            }
        }

        return LedgerProjection(
            vials: vials.values.sorted { $0.addedAt < $1.addedAt },
            doses: doses,
            symptoms: symptoms,
            weights: weights,
            notes: notes,
            sites: sites,
            supersededIds: superseded
        )
    }

    public func inventorySummary() -> String {
        if currentVials.isEmpty {
            return "No current vials."
        }
        return currentVials.map { vial in
            let remaining = vial.remainingVolume.map { $0.description } ?? "unknown remaining"
            return "\(vial.compoundName) (\(vial.id.uuidString.prefix(8))): \(remaining)"
        }.joined(separator: "\n")
    }
}
