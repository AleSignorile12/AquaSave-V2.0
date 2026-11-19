import SwiftUI

struct OnboardingSetup {
    let people: Int
    let name: String
    let sensors: [SensorPreset]
}

struct OnboardingView: View {
    let onFinish: (OnboardingSetup) -> Void

    @Environment(\.theme) private var theme

    @State private var page = 0
    @State private var people = 2
    @State private var name = ""
    @State private var picked = Set(SensorPreset.defaults.map(\.id))
    @FocusState private var nameFocused: Bool

    private let lastPage = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                pageView(title: "Every drop, counted.",
                         body: "AquaSave sensors clip onto your taps, shower heads and appliances. They measure every liter you use, and every liter you waste.") {
                    WaterDrop(level: 0.42, tint: theme.color)
                        .frame(width: 78, height: 122)
                }
                .tag(0)

                pageView(title: "Save water, earn credits.",
                         body: "Use less than your home's usual day and earn credits for sensor discounts, gift cards and more.") {
                    VStack(spacing: 22) {
                        CreditMark(size: 84, weight: 0.12)
                            .foregroundStyle(Color.credit)
                            .frame(width: 132, height: 132)
                            .background(Color.credit.opacity(0.12), in: .circle)
                        HStack(spacing: 12) {
                            IconCircle(systemImage: "dot.radiowaves.left.and.right", tint: theme.color, size: 44)
                            IconCircle(systemImage: "shippingbox.fill", tint: .orange, size: 44)
                            IconCircle(systemImage: "music.note", tint: .green, size: 44)
                            IconCircle(systemImage: "hands.and.sparkles.fill", tint: .pink, size: 44)
                        }
                    }
                }
                .tag(1)

                pageView(title: "How many people live in your household?",
                         body: "We'll measure your home for two weeks, then set a limit that steps down toward an efficient target.",
                         compact: true) {
                    householdPicker
                }
                .tag(2)

                profileStep
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0...lastPage, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? theme.color : Color.secondary.opacity(0.3))
                        .frame(width: index == page ? 20 : 8, height: 8)
                }
            }
            .animation(.spring(duration: 0.3, bounce: 0), value: page)
            .padding(.vertical, 16)
            .accessibilityHidden(true)

            Button {
                if page < lastPage {
                    withAnimation(.spring(duration: 0.4, bounce: 0)) { page += 1 }
                } else {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onFinish(OnboardingSetup(people: people, name: trimmed,
                                             sensors: SensorPreset.all.filter { picked.contains($0.id) }))
                }
            } label: {
                Text(page < lastPage ? "Continue" : "Start saving")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .disabled(page == lastPage && picked.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
        .onChange(of: page) { nameFocused = false }
    }

    // MARK: - Household

    private var householdPicker: some View {
        VStack(spacing: 16) {
            HStack(spacing: 28) {
                stepButton("minus", enabled: people > 1) { people -= 1 }
                Text("\(people)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(people)))
                    .frame(minWidth: 70)
                stepButton("plus", enabled: people < 8) { people += 1 }
            }
            .animation(.snappy(duration: 0.2), value: people)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("People in your household")
            .accessibilityValue("\(people)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: people = min(people + 1, 8)
                case .decrement: people = max(people - 1, 1)
                @unknown default: break
                }
            }

            Label("Target: \(Int(Credits.target(household: people))) L a day", systemImage: "drop.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(theme.color.opacity(0.12), in: .capsule)
                .contentTransition(.numericText())
        }
        .sensoryFeedback(.selection, trigger: people)
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .disabled(!enabled)
    }

    // MARK: - Profile

    private var profileStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set up your home")
                        .font(.title.weight(.bold))
                    Text("Tell us your name and which fixtures have a sensor. You can add more later.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Your name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("First name", text: $name)
                        .font(.title3)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Sensors to track")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(picked.count) selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(SensorPreset.all) { preset in
                            sensorTile(preset)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.selection, trigger: picked)
    }

    private func sensorTile(_ preset: SensorPreset) -> some View {
        let on = picked.contains(preset.id)
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                if on { picked.remove(preset.id) } else { picked.insert(preset.id) }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    IconCircle(systemImage: preset.category.systemImage, tint: on ? preset.category.tint : .secondary, size: 38)
                    Spacer()
                    Image(systemName: on ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(on ? theme.color : Color.secondary.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(preset.location).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(on ? theme.color : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.pressable)
        .foregroundStyle(.primary)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - Layout

    private func pageView<Art: View>(title: String, body: String, compact: Bool = false,
                                     @ViewBuilder art: () -> Art) -> some View {
        VStack(spacing: 36) {
            Spacer()
            art()
            VStack(spacing: 12) {
                Text(title)
                    .font(compact ? .title.weight(.bold) : .largeTitle.weight(.bold))
                Text(body)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingView { _ in }
}
