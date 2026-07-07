import SwiftData
import SwiftUI

@MainActor
enum DataSeeder {
    /// Seeds only non-user data (the shop catalog). No demo goals, balances,
    /// or progress are created — the app starts with a clean slate.
    static func seedIfNeeded(context: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(profileDescriptor)) ?? []
        if profiles.isEmpty {
            context.insert(UserProfile())
        }

        let upgradeDescriptor = FetchDescriptor<Upgrade>()
        let upgrades = (try? context.fetch(upgradeDescriptor)) ?? []
        if upgrades.isEmpty {
            for upgrade in Upgrade.catalog() {
                context.insert(upgrade)
            }
        }

        try? context.save()
    }
}
