import SwiftUI
import UIKit
import PhotosUI
import LedgerCore
import LabelOCR

struct CaptureScreen: View {
    @Environment(AppState.self) private var appState
    @State private var dictation = DictationController()
    @State private var listening = false
    @State private var accepted: Set<Int> = []
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ramble. Confirm. Nothing is filed until you tap accept.")
                        .foregroundStyle(Palette.muted)
                    TextField("What happened", text: Bindable(appState).ramble, axis: .vertical)
                        .lineLimit(4...12)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button(listening ? "Stop mic" : "Mic") {
                            if listening {
                                dictation.stop()
                                listening = false
                            } else {
                                dictation.onPartial = { text in appState.ramble = text }
                                try? dictation.start()
                                listening = true
                            }
                        }
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Vial photo", systemImage: "camera")
                        }
                        Button("Propose") {
                            Task { await appState.propose() }
                        }
                        .disabled(appState.ramble.isEmpty || appState.isProposing)
                        .buttonStyle(.borderedProminent)
                    }
                    if !appState.ocrText.isEmpty {
                        Text("OCR (not filed): \(appState.ocrText)")
                            .font(.footnote)
                    }
                    if appState.isProposing {
                        ProgressView("Asking your provider…")
                    }
                    if let error = appState.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                    if let proposal = appState.proposal {
                        ProposalCard(proposal: proposal, accepted: $accepted) {
                            Task { await appState.confirm(accepted: IndexSet(accepted)) }
                        }
                    }
                }
                .padding()
            }
            .background(Palette.paper)
            .navigationTitle("Capture")
            .onChange(of: pickerItem) { _, item in
                Task { await ingest(item) }
            }
        }
    }

    func ingest(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data)?.cgImage {
            #if canImport(Vision)
            if let result = try? await LabelRecognizer().recognize(cgImage: image) {
                appState.applyOCR(result.text)
            }
            #endif
        }
    }
}

struct ProposalCard: View {
    var proposal: Proposal
    @Binding var accepted: Set<Int>
    var onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proposed rows").font(.headline)
            ForEach(Array(proposal.events.enumerated()), id: \.offset) { index, event in
                Toggle(isOn: Binding(
                    get: { accepted.contains(index) },
                    set: { on in
                        if on { accepted.insert(index) } else { accepted.remove(index) }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text(event.kind.rawValue).font(.subheadline.weight(.semibold))
                        if let excerpt = event.excerpt {
                            Text(excerpt).font(.footnote)
                        }
                    }
                }
                .onAppear { accepted.insert(index) }
            }
            if !proposal.gaps.isEmpty {
                Text("Gaps").font(.headline)
                ForEach(proposal.gaps, id: \.self) { gap in
                    Text("• \(gap)").font(.footnote)
                }
            }
            Button("File accepted rows", action: onCommit)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
