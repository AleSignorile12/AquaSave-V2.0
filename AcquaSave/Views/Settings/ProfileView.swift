import SwiftUI
import SwiftData

/// Settings: who you are, how your limit works, how the app looks.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    @Query(sort: \DayResult.day) private var results: [DayResult]

    @AppStorage("household") private var household = 2
    @AppStorage("userName") private var userName = ""
    @AppStorage("accentTheme") private var accent = AccentTheme.emerald
    @AppStorage("appearance") private var appearance = Appearance.system
    @AppStorage("showSimulators") private var showSimulators = true

    @State private var confirmReset = false

    var body: some View {
        let plan = Ledger.plan(results, household: household)
        let target = Credits.target(household: household)
        let progress = TierProgress(results)

        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Text(initials)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(theme.color.gradient, in: .circle)
                        VStack(alignment: .leading, spacing: 3) {
                            TextField("Your name", text: $userName)
                                .font(.title3.weight(.semibold))
                                .textContentType(.givenName)
                                .submitLabel(.done)
                            Label("\(progress.tier.name) tier", systemImage: progress.tier.systemImage)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(progress.tier.tint)
                        }
                    }
                    .padding(.vertical, 4)

                    Stepper(value: $household, in: 1...8) {
                        LabeledContent("People in your household", value: "\(household)")
                    }
                } footer: {
                    Text("Sets your target: \(Int(Credits.targetPerPerson)) L per person, \(Int(target)) L a day.")
                }

                Section {
                    if let baseline = plan.baseline {
                        LabeledContent("Your usual day", value: "\(Int(Credits.effectiveBaseline(baseline, household: household))) L")
                        LabeledContent("Today's limit", value: "\(Int(plan.limit)) L")
                        LabeledContent("Target", value: "\(Int(target)) L")
                    } else {
                        LabeledContent("Measuring your usual day",
                                       value: "Day \(plan.calibrationDay ?? 1) of \(Credits.calibrationDays)")
                    }
                    DisclosureGroup("How your limit is set") {
                        Text("For your first \(Credits.calibrationDays) days we measure how much water your home usually uses. Your limit then starts 15% below that and drops 5% each month until it reaches \(Int(Credits.targetPerPerson)) L per person, the UK standard for efficient new homes. Your usual day never counts as more than \(Int(Credits.capPerPerson)) L per person, the European average, so using extra water at the start can't buy an easy limit.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Your limit")
                } footer: {
                    Text("You earn 1 credit for every \(Int(Credits.litersPerCredit)) L you use below your usual day, plus your tier's boost. Days with an offline sensor don't earn.")
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent")
                        HStack(spacing: 0) {
                            ForEach(AccentTheme.allCases) { option in
                                swatch(option)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle(isOn: $showSimulators) {
                        Label("Reading simulators", systemImage: "flask")
                    }
                } header: {
                    Text("Beta")
                } footer: {
                    Text("Adds buttons to Today that log a fake shower, leak or warm-up, so you can try AquaSave without sensors.")
                }

                Section {
                    NavigationLink { ShopView() } label: {
                        Label("Sensor Shop", systemImage: "bag")
                    }
                }

                Section {
                    Button("Reset demo data", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Sensors aren't connected yet, so AquaSave runs on simulated readings. Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0").")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset demo data?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    DemoData.reset(context, household: household)
                }
            } message: {
                Text("Replaces all readings, credits and redeemed rewards with fresh simulated data for your current sensors.")
            }
            .sensoryFeedback(.selection, trigger: accent)
        }
    }

    private var initials: String {
        let letters = userName.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "🙂" : String(letters).uppercased()
    }

    private func swatch(_ option: AccentTheme) -> some View {
        let on = accent == option
        return Button {
            withAnimation(.snappy) { accent = option }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(option.color.gradient)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .opacity(on ? 1 : 0)
                    }
                    .padding(3)
                    .overlay(Circle().strokeBorder(on ? option.color : .clear, lineWidth: 2))
                Text(option.name)
                    .font(.caption2.weight(on ? .semibold : .regular))
                    .foregroundStyle(on ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.name) accent")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
