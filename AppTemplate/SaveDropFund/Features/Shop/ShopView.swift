import SwiftData
import SwiftUI

@Observable
@MainActor
final class ShopViewModel {
    var selectedUpgrade: Upgrade?
    var showingPurchaseSheet = false
}

struct ShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Upgrade.cost) private var upgrades: [Upgrade]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = ShopViewModel()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    ForEach(upgrades, id: \.id) { upgrade in
                        Button {
                            viewModel.selectedUpgrade = upgrade
                            viewModel.showingPurchaseSheet = true
                        } label: {
                            upgradeCard(upgrade)
                        }
                        .buttonStyle(.plain)
                        .disabled(upgrade.isInstalled)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingPurchaseSheet) {
                if let upgrade = viewModel.selectedUpgrade {
                    purchaseSheet(for: upgrade)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Upgrades")
                    .font(Theme.serifTitle(32))
                    .foregroundStyle(Theme.textBrown)
                Text("Enhance your board")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.gold)
                Text("\(profile?.points ?? 0)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.cardBrown)
            .clipShape(Capsule())
        }
    }

    private func upgradeCard(_ upgrade: Upgrade) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(upgrade.iconName)
                .resizable()
                .padding(6)
                .frame(width: 52, height: 52)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(upgrade.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if upgrade.isInstalled {
                        Text("Installed")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.successGreen.opacity(0.15))
                            .foregroundStyle(Theme.successGreen)
                            .clipShape(Capsule())
                    } else {
                        Text("\(upgrade.cost) pts")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.goldDark)
                    }
                }
                Text(upgrade.upgradeDescription)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.leading)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private func purchaseSheet(for upgrade: Upgrade) -> some View {
        VStack(spacing: 20) {
            Image(systemName: upgrade.iconName)
                .resizable()
                .padding(6)
                .frame(width: 80, height: 80)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text(upgrade.name)
                .font(Theme.serifTitle(24))

            Text(upgrade.upgradeDescription)
                .font(.body)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)

            if upgrade.isInstalled {
                Text("Already Installed")
                    .font(.headline)
                    .foregroundStyle(Theme.successGreen)
            } else {
                PrimaryButton(
                    title: "Unlock • \(upgrade.cost) pts",
                    isEnabled: (profile?.points ?? 0) >= upgrade.cost
                ) {
                    purchase(upgrade)
                }
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    private func purchase(_ upgrade: Upgrade) {
        guard let profile, profile.points >= upgrade.cost else { return }
        profile.points -= upgrade.cost
        upgrade.isInstalled = true
        try? modelContext.save()
        viewModel.showingPurchaseSheet = false
    }
}
