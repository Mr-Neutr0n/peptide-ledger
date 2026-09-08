import SwiftUI
import LedgerCore

struct LedgerScreen: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List(appState.events.reversed()) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.kind.rawValue).font(.headline)
                        .accessibilityIdentifier("ledger.row.\(event.kind.rawValue)")
                    Text(event.occurredAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                    if let excerpt = event.excerpt {
                        Text(excerpt).font(.footnote)
                    }
                    if appState.projection.supersededIds.contains(event.id) {
                        Text("superseded").font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
            .accessibilityIdentifier("ledger.list")
            .navigationTitle("Ledger")
            .overlay {
                if appState.events.isEmpty {
                    Text("No rows yet. Capture a ramble and confirm it.")
                        .foregroundStyle(Palette.muted)
                }
            }
        }
    }
}
