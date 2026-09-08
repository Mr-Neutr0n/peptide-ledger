import SwiftUI
import UniformTypeIdentifiers
import ModelClient

struct MoreScreen: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Export") { ExportScreen() }
                NavigationLink("Settings") { SettingsScreen() }
            }
            .navigationTitle("More")
        }
    }
}

struct ExportScreen: View {
    @Environment(AppState.self) private var appState
    @State private var jsonURL: URL?
    @State private var csvURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Full archive. JSONL is the event log. CSV is a flattened table. Both stay on the phone until you share them.")
            if let jsonURL {
                ShareLink(item: jsonURL) {
                    Label("Share JSONL", systemImage: "square.and.arrow.up")
                }
            }
            if let csvURL {
                ShareLink(item: csvURL) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding()
        .navigationTitle("Export")
        .task {
            let dir = FileManager.default.temporaryDirectory
            let json = dir.appendingPathComponent("ledger.jsonl")
            let csv = dir.appendingPathComponent("ledger.csv")
            let jsonl = (try? await appState.jsonlData()) ?? Data()
            try? jsonl.write(to: json)
            try? await appState.csvText().write(to: csv, atomically: true, encoding: .utf8)
            jsonURL = json
            csvURL = csv
        }
    }
}

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @State private var newKey = ""
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Kind", selection: Bindable(appState).providerKind) {
                    Text("Anthropic").tag(ProviderKind.anthropic)
                    Text("OpenAI-compatible").tag(ProviderKind.openaiCompatible)
                }
                TextField("Model", text: Bindable(appState).modelName)
                TextField("Base URL", text: Bindable(appState).baseURLString)
                LabeledContent("Key stored") {
                    Text(appState.hasKey ? "yes, Keychain" : "no")
                }
                SecureField("Rotate key", text: $newKey)
                Button("Save key") {
                    try? appState.saveKey(newKey)
                    newKey = ""
                }
                Button("Delete key", role: .destructive) {
                    try? appState.clearKey()
                }
            }
            Section("This phone") {
                Button("Delete everything", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Delete ledger, sessions, and key?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                Task { try? await appState.deleteEverything() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
