import Foundation
import DoseMath
import LedgerCore
import ModelClient
import LabelOCR

public struct Clerk: Sendable {
    public var provider: any ModelProvider
    public var tools: ToolRuntime

    public init(provider: any ModelProvider, tools: ToolRuntime = ToolRuntime()) {
        self.provider = provider
        self.tools = tools
    }

    public func proposeEvents(
        ramble: String,
        ocrText: String? = nil,
        ledgerSummary: String = ""
    ) async throws -> Proposal {
        var user = ramble
        if let ocrText, !ocrText.isEmpty {
            user += "\n\nVial label text (OCR candidates, not confirmed):\n\(ocrText)"
        }
        if !ledgerSummary.isEmpty {
            user += "\n\nCurrent ledger summary:\n\(ledgerSummary)"
        }
        let messages = [
            ChatMessage(role: "system", content: ClerkPrompt.system),
            ChatMessage(role: "user", content: user),
        ]
        let raw = try await provider.complete(messages: messages, jsonObject: true)
        return try ProposalParser.parse(raw)
    }

    public func commit(
        proposal: Proposal,
        accepted: IndexSet,
        store: EventStore,
        now: Date = Date()
    ) async throws -> [LedgerEvent] {
        var committed: [LedgerEvent] = []
        for (index, proposed) in proposal.events.enumerated() where accepted.contains(index) {
            let event = LedgerEvent(
                occurredAt: proposed.occurredAt ?? now,
                recordedAt: now,
                kind: proposed.kind,
                payload: proposed.payload,
                excerpt: proposed.excerpt
            )
            try await store.append(event)
            committed.append(event)
        }
        return committed
    }

    public func supersede(
        eventId: UUID,
        replacement: LedgerEvent,
        reason: String?,
        store: EventStore
    ) async throws {
        let marker = LedgerEvent(
            occurredAt: replacement.occurredAt,
            kind: .eventSuperseded,
            payload: .eventSuperseded(EventSupersededPayload(supersedes: eventId, reason: reason))
        )
        try await store.append(marker)
        try await store.append(replacement)
    }

    public func attachPhoto(vialId: UUID, relativePath: String, store: EventStore) async throws {
        let event = LedgerEvent(
            occurredAt: Date(),
            kind: .noteAdded,
            payload: .noteAdded(NoteAddedPayload(text: "photo \(relativePath) attached to vial \(vialId)"))
        )
        try await store.append(event)
    }

    public func recognizeLabelText(_ text: String) -> LabelCandidate {
        LabelFieldParser.parse(text)
    }
}
