import Testing
import Foundation
import DoseMath
import LedgerCore
import ModelClient
@testable import Clerk

@Suite("clerk proposes; user confirms")
struct ClerkTests {
    @Test("proposal is not written until commit")
    func proposeThenCommit() async throws {
        let json = """
        {"events":[{"kind":"doseLogged","excerpt":"250 mcg BPC","payload":{"compoundName":"BPC-157","doseMass":{"value":250,"unit":"mcg"},"site":"left abdomen"}}],"gaps":["which vial"]}
        """
        let clerk = Clerk(provider: MockProvider(defaultResponse: json))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try EventStore(directory: dir)
        let proposal = try await clerk.proposeEvents(ramble: "took 250 mcg BPC left belly")
        #expect(proposal.events.count == 1)
        #expect(proposal.gaps.contains("which vial"))
        #expect(await store.allEvents().isEmpty)
        let committed = try await Clerk.commit(proposal: proposal, accepted: IndexSet(integer: 0), store: store)
        #expect(committed.count == 1)
        #expect(await store.allEvents().count == 1)
        let none = try await Clerk.commit(proposal: proposal, accepted: IndexSet(), store: store)
        #expect(none.isEmpty)
        #expect(await store.allEvents().count == 1)
    }

    @Test("system prompt refuses to prescribe")
    func stance() {
        #expect(ClerkPrompt.system.contains("must not"))
        #expect(ClerkPrompt.system.contains("recommend") || ClerkPrompt.system.contains("suggest"))
        #expect(ClerkPrompt.system.contains("arithmetic") || ClerkPrompt.system.contains("DoseMath"))
    }

    @Test("reconstitute and draw_volume tools are DoseMath, not the model")
    func localTools() throws {
        let tools = ToolRuntime()
        let recon = try tools.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 2))
        #expect(recon.text.contains("2.5"))
        let conc = try Concentration.reconstitute(mass: Mass(5, .milligram), diluent: Volume(milliliters: 2))
        let draw = try tools.drawVolume(dose: Mass(5, .milligram), concentration: conc, vialMass: Mass(5, .milligram), vialVolume: Volume(milliliters: 2))
        #expect(draw.flags.contains { $0.code == "dose_equals_entire_vial" })
    }

    @Test("session tree keeps parent ids")
    func sessions() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sessions = try SessionStore(directory: dir)
        let root = SessionMessage(role: "user", content: "hi")
        try await sessions.append(root)
        let child = SessionMessage(parentId: root.id, role: "assistant", content: "filed nothing")
        try await sessions.append(child)
        let lineage = await sessions.lineage(of: child.id)
        #expect(lineage.map(\.id) == [root.id, child.id])
        let compact = await sessions.compact(keepingLast: 1)
        #expect(compact.note.contains("stubbed"))
    }
}
