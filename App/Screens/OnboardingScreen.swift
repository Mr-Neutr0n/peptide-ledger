import SwiftUI
import ModelClient

struct OnboardingScreen: View {
    @Environment(AppState.self) private var appState
    @State private var key = ""
    @State private var accepted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This is a filing clerk, not a clinic.")
                        .font(.title2)
                    Text("It records doses, vials, reconstitutions, symptoms, and weights that you already decided. It does not recommend a dose, compound, protocol, or vendor. It is not a medical device. You must be 17 or older.")
                    Text("Storage is on this phone. The only network call is the model provider you choose, using a key you paste. There is no company server.")
                    Toggle("I am 17 or older and I understand this app does not give medical advice.", isOn: $accepted)
                        .accessibilityIdentifier("onboarding.accept")
                    Picker("Provider", selection: Bindable(appState).providerKind) {
                        Text("Anthropic").tag(ProviderKind.anthropic)
                        Text("OpenAI-compatible").tag(ProviderKind.openaiCompatible)
                    }
                    TextField("Model id", text: Bindable(appState).modelName)
                        .textInputAutocapitalization(.never)
                    TextField("Base URL", text: Bindable(appState).baseURLString)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    SecureField("API key (Keychain, this device only)", text: $key)
                    Button("Save key and continue") {
                        appState.acceptDisclaimer()
                        try? appState.saveKey(key)
                        appState.finishOnboarding()
                    }
                    .disabled(!accepted)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("onboarding.continue")
                }
                .padding()
            }
            .background(Palette.paper)
            .navigationTitle("Before you file")
        }
    }
}
