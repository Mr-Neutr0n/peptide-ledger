import Testing
import Foundation
import DoseMath
@testable import LedgerCore

@Suite("append-only event store and projections")
struct LedgerCoreTests {
    func tempStore() throws -> EventStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try EventStore(directory: dir)
    }

    @Test("append then rebuild from JSONL")
    func appendAndRebuild() async throws {
        let store = try tempStore()
        let vialId = UUID()
        try await store.append(LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            kind: .vialAdded,
            payload: .vialAdded(VialAddedPayload(
                vialId: vialId,
                compoundName: "BPC-157",
                labeledMass: Mass(5, .milligram),
                lot: "LOT-1"
            ))
        ))
        try await store.append(LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 1_700_000_100),
            kind: .vialReconstituted,
            payload: .vialReconstituted(VialReconstitutedPayload(
                vialId: vialId,
                diluentVolume: Volume(milliliters: 2),
                diluentName: "BAC"
            ))
        ))
        try await store.append(LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 1_700_000_200),
            kind: .doseLogged,
            payload: .doseLogged(DoseLoggedPayload(
                vialId: vialId,
                compoundName: "BPC-157",
                doseMass: Mass(250, .microgram),
                drawVolume: Volume(milliliters: Decimal(string: "0.1")!),
                site: "left abdomen"
            ))
        ))
        let data = try await store.jsonlData()
        let cloneDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let clone = try EventStore(directory: cloneDir)
        let added = try await clone.importJSONL(data)
        #expect(added == 3)
        let projection = await clone.projection()
        #expect(projection.currentVials.count == 1)
        #expect(projection.currentVials[0].remainingVolume?.milliliters == Decimal(string: "1.9"))
        #expect(projection.doses.count == 1)
        #expect(projection.sites == ["left abdomen"])
        #expect(projection.currentVials[0].concentration?.microgramsPerMilliliter == 2500)
    }

    @Test("corrections are supersede events, not in-place edits")
    func supersede() async throws {
        let store = try tempStore()
        let original = LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 10),
            kind: .doseLogged,
            payload: .doseLogged(DoseLoggedPayload(compoundName: "TB-500", doseMass: Mass(500, .microgram), site: "left"))
        )
        try await store.append(original)
        try await store.append(LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 11),
            kind: .eventSuperseded,
            payload: .eventSuperseded(EventSupersededPayload(supersedes: original.id, reason: "wrong site"))
        ))
        let replacement = LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 10),
            kind: .doseLogged,
            payload: .doseLogged(DoseLoggedPayload(compoundName: "TB-500", doseMass: Mass(500, .microgram), site: "right"))
        )
        try await store.append(replacement)
        let projection = await store.projection()
        #expect(projection.supersededIds.contains(original.id))
        #expect(projection.doses.count == 1)
        if case .doseLogged(let payload) = projection.doses[0].payload {
            #expect(payload.site == "right")
        } else {
            Issue.record("expected dose")
        }
        #expect(await store.allEvents().count == 3)
    }

    @Test("CSV export contains every event")
    func csv() async throws {
        let store = try tempStore()
        try await store.append(LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 1),
            kind: .noteAdded,
            payload: .noteAdded(NoteAddedPayload(text: "hello, world")),
            excerpt: "said hello"
        ))
        let csv = LedgerExport.csv(from: await store.allEvents())
        #expect(csv.contains("noteAdded"))
        #expect(csv.contains("\"hello, world\""))
        #expect(csv.contains("said hello"))
    }

    @Test("import skips duplicate ids")
    func skipDupes() async throws {
        let store = try tempStore()
        let event = LedgerEvent(
            occurredAt: Date(timeIntervalSince1970: 1),
            kind: .weightLogged,
            payload: .weightLogged(WeightLoggedPayload(kilograms: 80))
        )
        try await store.append(event)
        let data = try LedgerExport.jsonl(from: [event])
        let added = try await store.importJSONL(data)
        #expect(added == 0)
        #expect(await store.allEvents().count == 1)
    }

    @Test("discarded vials leave the current stash")
    func discard() async throws {
        let store = try tempStore()
        let id = UUID()
        try await store.append(LedgerEvent(
            occurredAt: Date(),
            kind: .vialAdded,
            payload: .vialAdded(VialAddedPayload(vialId: id, compoundName: "CJC-1295"))
        ))
        try await store.append(LedgerEvent(
            occurredAt: Date(),
            kind: .vialDiscarded,
            payload: .vialDiscarded(VialDiscardedPayload(vialId: id, reason: "expired"))
        ))
        #expect(await store.projection().currentVials.isEmpty)
        #expect(await store.projection().vials.count == 1)
    }
}
