import SwiftData
import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            GoalsListView()
                .tabItem { Label("Goals", systemImage: "target") }
                .tag(AppTab.goals)

            DepositView(selectedTab: $selectedTab)
                .tabItem { Label("Deposit", systemImage: "arrow.up.circle.fill") }
                .tag(AppTab.deposit)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag.fill") }
                .tag(AppTab.shop)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                .tag(AppTab.analytics)
        }
        .tint(Theme.goldDark)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Goal.self, Deposit.self, DropResult.self, Upgrade.self, Challenge.self, UserProfile.self], inMemory: true)
}
