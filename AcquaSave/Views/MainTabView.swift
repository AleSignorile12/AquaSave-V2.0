import SwiftUI

// MARK: - Lazy View Wrapper
// Ritarda la costruzione della schermata finché non serve davvero.

struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

// MARK: - Main Tab View

struct MainTabView: View {

    // MARK: - Tabs

    enum Tab: Hashable {
        case home
        case stats
        case rewards
        case devices
    }

    // MARK: - State

    @State private var selection: Tab = .home

    // MARK: - Body

    var body: some View {
        TabView(selection: $selection) {
            homeTab
            statsTab
            rewardsTab
            devicesTab
        }
        .tint(.green)
        .animation(.easeInOut(duration: 0.18), value: selection)
        .onChange(of: selection) { _, _ in
            HapticManager.light()
        }
    }

    // MARK: - Individual Tabs

    private var homeTab: some View {
        LazyView(DashboardView())
            .tabItem {
                Label("Home", systemImage: "drop.fill")
            }
            .tag(Tab.home)
    }

    private var statsTab: some View {
        LazyView(StatsView())
            .tabItem {
                Label("Stats", systemImage: "chart.xyaxis.line")
            }
            .tag(Tab.stats)
    }

    private var rewardsTab: some View {
        LazyView(RewardsView())
            .tabItem {
                Label("Rewards", systemImage: "wallet.pass.fill")
            }
            .tag(Tab.rewards)
    }

    private var devicesTab: some View {
        LazyView(DevicesView())
            .tabItem {
                Label("Devices", systemImage: "dot.radiowaves.left.and.right")
            }
            .tag(Tab.devices)
    }
}
