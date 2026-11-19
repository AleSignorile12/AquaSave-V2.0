import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case today, insights, rewards, devices
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("household") private var household = 2
    @AppStorage("userName") private var userName = ""
    @AppStorage("accentTheme") private var theme = AccentTheme.emerald
    @AppStorage("appearance") private var appearance = Appearance.system

    @State private var tab: AppTab = .today

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "drop.fill", value: .today) {
                TodayView(tab: $tab)
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: .insights) {
                InsightsView()
            }
            Tab("Rewards", systemImage: "gift.fill", value: .rewards) {
                RewardsView()
            }
            Tab("Devices", systemImage: "dot.radiowaves.left.and.right", value: .devices) {
                DevicesView()
            }
        }
        .tabBarMinimizeBehavior(.never)
        .fullScreenCover(isPresented: .init(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView { setup in
                household = setup.people
                userName = setup.name
                hasOnboarded = true
                prepare(presets: setup.sensors)
            }
        }
        // Outermost, so the onboarding cover and every sheet get the accent too.
        .tint(theme.color)
        .environment(\.theme, theme)
        .preferredColorScheme(appearance.scheme)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { prepare() }
        }
    }

    /// Seeds demo readings once, then closes any days that ended since the last launch.
    private func prepare(presets: [SensorPreset] = SensorPreset.defaults) {
        guard hasOnboarded else { return }
        if !didSeed {
            DemoData.seed(context, household: household, presets: presets)
            didSeed = true
        }
        try? Ledger.settle(context, household: household)
    }
}
