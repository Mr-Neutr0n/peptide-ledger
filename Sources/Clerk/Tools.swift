import Foundation
import DoseMath
import LedgerCore

public enum ClerkToolName: String, Sendable, CaseIterable {
    case proposeEvents = "propose_events"
    case commitEvents = "commit_events"
    case reconstitute = "reconstitute"
    case drawVolume = "draw_volume"
    case vialUpsert = "vial_upsert"
    case inventoryRemaining = "inventory_remaining"
    case attachPhoto = "attach_photo"
    case queryLedger = "query_ledger"
}

public struct ToolResult: Sendable, Equatable {
    public var name: ClerkToolName
    public var ok: Bool
    public var text: String
    public var proposal: Proposal?
    public var flags: [SanityFlag]

    public init(name: ClerkToolName, ok: Bool, text: String, proposal: Proposal? = nil, flags: [SanityFlag] = []) {
        self.name = name
        self.ok = ok
        self.text = text
        self.proposal = proposal
        self.flags = flags
    }
}

public enum ClerkToolError: Error, Sendable, Equatable {
    case unknownTool
    case unconfirmedCommit
    case missingArgument(String)
}

/// Local tools. `propose_events` is the only model-backed one; everything else is deterministic.
public struct ToolRuntime: Sendable {
    public init() {}

    public func reconstitute(mass: Mass, diluent: Volume) throws -> ToolResult {
        let conc = try Concentration.reconstitute(mass: mass, diluent: diluent)
        let text = "concentration = \(mass) / \(diluent) = \(conc)"
        return ToolResult(name: .reconstitute, ok: true, text: text)
    }

    public func drawVolume(
        dose: Mass,
        concentration: Concentration,
        scale: SyringeScale = .u100,
        vialMass: Mass? = nil,
        vialVolume: Volume? = nil
    ) throws -> ToolResult {
        let draw = try DrawVolume.compute(
            dose: dose,
            concentration: concentration,
            scale: scale,
            vialMass: vialMass,
            vialVolume: vialVolume
        )
        return ToolResult(name: .drawVolume, ok: true, text: draw.formula, flags: draw.flags)
    }

    public func inventoryRemaining(_ projection: LedgerProjection) -> ToolResult {
        ToolResult(name: .inventoryRemaining, ok: true, text: projection.inventorySummary())
    }

    public func queryLedger(_ projection: LedgerProjection, question: String) -> ToolResult {
        let lower = question.lowercased()
        if lower.contains("site") {
            let last = projection.sites.suffix(8).joined(separator: ", ")
            return ToolResult(
                name: .queryLedger,
                ok: true,
                text: last.isEmpty ? "No injection sites on file." : "Recent sites: \(last)"
            )
        }
        if lower.contains("weight") {
            return ToolResult(
                name: .queryLedger,
                ok: true,
                text: "\(projection.weights.count) weight rows on file."
            )
        }
        return ToolResult(name: .queryLedger, ok: true, text: projection.inventorySummary())
    }
}
