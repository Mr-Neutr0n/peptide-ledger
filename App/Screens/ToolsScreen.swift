import SwiftUI
import DoseMath

struct ToolsScreen: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Form {
                Section("Vial (your numbers)") {
                    TextField("Mass", text: Bindable(appState).reconstitutionMass)
                        .keyboardType(.decimalPad)
                    Picker("Mass unit", selection: Bindable(appState).reconstitutionMassUnit) {
                        Text("mg").tag(MassUnit.milligram)
                        Text("mcg").tag(MassUnit.microgram)
                    }
                    TextField("Diluent mL", text: Bindable(appState).reconstitutionDiluent)
                        .keyboardType(.decimalPad)
                }
                Section("Dose (your numbers)") {
                    TextField("Dose", text: Bindable(appState).intendedDose)
                        .keyboardType(.decimalPad)
                    Picker("Dose unit", selection: Bindable(appState).intendedDoseUnit) {
                        Text("mg").tag(MassUnit.milligram)
                        Text("mcg").tag(MassUnit.microgram)
                    }
                    Picker("Syringe", selection: Bindable(appState).syringeScale) {
                        ForEach(SyringeScale.allCases, id: \.self) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                }
                Button("Show work") { appState.computeDraw() }
                if let draw = appState.lastDraw {
                    Section("Formula") {
                        Text(draw.formula).font(.system(.footnote, design: .monospaced))
                        ForEach(draw.inputs.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key, value: value)
                        }
                    }
                    Section("Result") {
                        Text("Draw \(draw.volume.description)")
                        Text("\(draw.scale.rawValue) marks: \(DoseFormat.decimal(draw.syringeUnits))")
                    }
                    if !draw.flags.isEmpty {
                        Section("Flags") {
                            ForEach(draw.flags, id: \.code) { flag in
                                Text(flag.message).foregroundStyle(.orange)
                            }
                        }
                    }
                }
                if let error = appState.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("Reconstitution")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
