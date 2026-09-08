import SwiftUI

struct LockScreen: View {
    @Environment(AppState.self) private var appState
    @State private var failed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Peptide Ledger")
                .font(.largeTitle)
            Text("On-device log. Unlock with Face ID or passcode.")
                .font(.body)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
            Button("Unlock") {
                Task {
                    let ok = await AuthLock.authenticate()
                    appState.unlocked = ok
                    failed = !ok
                }
            }
            .buttonStyle(.borderedProminent)
            if failed {
                Text("Unlock failed.")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
        .task {
            let ok = await AuthLock.authenticate()
            appState.unlocked = ok
        }
    }
}
