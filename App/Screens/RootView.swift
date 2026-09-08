import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.unlocked {
                LockScreen()
            } else if !appState.onboardingComplete {
                OnboardingScreen()
            } else {
                MainTabs()
            }
        }
        .tint(Palette.accent)
    }
}

enum Palette {
    static let paper = Color(red: 0.984, green: 0.965, blue: 0.918)
    static let ink = Color(red: 0.102, green: 0.098, blue: 0.086)
    static let accent = Color(red: 0.541, green: 0.239, blue: 0.141)
    static let muted = Color(red: 0.361, green: 0.341, blue: 0.306)
}

struct MainTabs: View {
    var body: some View {
        TabView {
            Tab("Capture", systemImage: "mic") { CaptureScreen() }
            Tab("Ledger", systemImage: "list.bullet") { LedgerScreen() }
            Tab("Vials", systemImage: "archivebox") { VialsScreen() }
            Tab("Tools", systemImage: "function") { ToolsScreen() }
            Tab("More", systemImage: "ellipsis") { MoreScreen() }
        }
    }
}
