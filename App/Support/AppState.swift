import Foundation
import Observation
import LedgerCore
import DoseMath
import Clerk
import ModelClient
import LabelOCR

@Observable
@MainActor
final class AppState {
    var unlocked = false
    var onboardingComplete: Bool
    var disclaimerAccepted: Bool
    var providerKind: ProviderKind
    var modelName: String
    var baseURLString: String
    var hasKey: Bool
    var ramble: String = ""
    var ocrText: String = ""
    var streamingPreview: String = ""
    var proposal: Proposal?
    var isProposing = false
    var errorMessage: String?
    var events: [LedgerEvent] = []
    var projection = LedgerProjection.build(from: [])
    var reconstitutionMass: String = "5"
    var reconstitutionMassUnit: MassUnit = .milligram
    var reconstitutionDiluent: String = "2"
    var intendedDose: String = "250"
    var intendedDoseUnit: MassUnit = .microgram
    var syringeScale: SyringeScale = .u100
    var lastDraw: DrawResult?

    let directory: URL
    private var store: EventStore?
    private var sessions: SessionStore?
    private let keychain = KeychainStore(service: "dev.neutr0n.peptideledger")
    private let defaults = UserDefaults.standard

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = appSupport.appendingPathComponent("peptide-ledger", isDirectory: true)
        onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        disclaimerAccepted = UserDefaults.standard.bool(forKey: "disclaimerAccepted")
        providerKind = ProviderKind(rawValue: UserDefaults.standard.string(forKey: "providerKind") ?? "") ?? .anthropic
        modelName = UserDefaults.standard.string(forKey: "modelName") ?? "claude-sonnet-4-5"
        baseURLString = UserDefaults.standard.string(forKey: "baseURL") ?? "https://api.anthropic.com"
        hasKey = false
        Task { await bootstrap() }
    }

    func bootstrap() async {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            store = try EventStore(directory: directory)
            sessions = try SessionStore(directory: directory)
            hasKey = (try? keychain.read(account: accountName))?.isEmpty == false
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var accountName: String { "api-key.\(providerKind.rawValue)" }

    func refresh() async {
        guard let store else { return }
        events = await store.allEvents()
        projection = await store.projection()
    }

    func acceptDisclaimer() {
        disclaimerAccepted = true
        defaults.set(true, forKey: "disclaimerAccepted")
    }

    func finishOnboarding() {
        onboardingComplete = true
        defaults.set(true, forKey: "onboardingComplete")
        defaults.set(providerKind.rawValue, forKey: "providerKind")
        defaults.set(modelName, forKey: "modelName")
        defaults.set(baseURLString, forKey: "baseURL")
    }

    func saveKey(_ key: String) throws {
        try keychain.set(key, account: accountName)
        hasKey = !key.isEmpty
    }

    func clearKey() throws {
        try keychain.delete(account: accountName)
        hasKey = false
    }

    func makeProvider() throws -> any ModelProvider {
        let key = try keychain.read(account: accountName) ?? ""
        if key.isEmpty { throw ModelClientError.emptyKey }
        let url = URL(string: baseURLString) ?? URL(string: "https://api.openai.com/v1")!
        switch providerKind {
        case .anthropic:
            return AnthropicProvider(config: ProviderConfig(kind: .anthropic, model: modelName, baseURL: url, apiKey: key))
        case .openaiCompatible:
            return OpenAICompatibleProvider(config: .openaiCompatible(model: modelName, baseURL: url, apiKey: key))
        }
    }

    func propose() async {
        isProposing = true
        errorMessage = nil
        defer { isProposing = false }
        do {
            let clerk = Clerk(provider: try makeProvider())
            if let sessions {
                try await sessions.append(SessionMessage(role: "user", content: ramble))
            }
            proposal = try await clerk.proposeEvents(
                ramble: ramble,
                ocrText: ocrText.isEmpty ? nil : ocrText,
                ledgerSummary: projection.inventorySummary()
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirm(accepted: IndexSet) async {
        guard let proposal, let store else { return }
        do {
            _ = try await Clerk.commit(proposal: proposal, accepted: accepted, store: store)
            self.proposal = nil
            ramble = ""
            ocrText = ""
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyOCR(_ text: String) {
        ocrText = text
    }

    func computeDraw() {
        errorMessage = nil
        guard let mass = Decimal(string: reconstitutionMass),
              let diluent = Decimal(string: reconstitutionDiluent),
              let dose = Decimal(string: intendedDose)
        else {
            errorMessage = "Mass, diluent, and dose must be numbers the user typed."
            return
        }
        do {
            let conc = try Concentration.reconstitute(
                mass: Mass(mass, reconstitutionMassUnit),
                diluent: Volume(milliliters: diluent)
            )
            lastDraw = try DrawVolume.compute(
                dose: Mass(dose, intendedDoseUnit),
                concentration: conc,
                scale: syringeScale,
                vialMass: Mass(mass, reconstitutionMassUnit),
                vialVolume: Volume(milliliters: diluent)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func jsonlData() async throws -> Data {
        guard let store else { return Data() }
        return try await store.jsonlData()
    }

    func csvText() async -> String {
        LedgerExport.csv(from: events)
    }

    func deleteEverything() async throws {
        try await store?.deleteEverything()
        try await sessions?.deleteEverything()
        try? keychain.delete(account: accountName)
        hasKey = false
        onboardingComplete = false
        disclaimerAccepted = false
        defaults.removeObject(forKey: "onboardingComplete")
        defaults.removeObject(forKey: "disclaimerAccepted")
        await refresh()
    }
}
