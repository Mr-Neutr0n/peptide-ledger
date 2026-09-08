import SwiftUI

struct VialsScreen: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List(appState.projection.currentVials) { vial in
                VStack(alignment: .leading, spacing: 4) {
                    Text(vial.compoundName).font(.headline)
                    if let mass = vial.labeledMass {
                        Text("Labeled \(mass.description)")
                    }
                    if let remaining = vial.remainingVolume {
                        Text("Remaining \(remaining.description)")
                    }
                    if let lot = vial.lot {
                        Text("Lot \(lot)").font(.footnote)
                    }
                    if let conc = vial.concentration {
                        Text(conc.description).font(.footnote)
                    }
                    Text(vial.storageNote ?? "")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
            }
            .navigationTitle("Vials")
            .overlay {
                if appState.projection.currentVials.isEmpty {
                    Text("No current vials.")
                        .foregroundStyle(Palette.muted)
                }
            }
        }
    }
}
