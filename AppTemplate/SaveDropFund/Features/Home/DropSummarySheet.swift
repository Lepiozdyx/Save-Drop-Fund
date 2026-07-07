import SwiftData
import SwiftUI

struct DropSummarySheet: View {
    let outcome: PlinkoDropOutcome
    let goals: [Goal]
    let ballValue: Double
    let onTransfer: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ConfettiView()
                .frame(height: 40)

            Text("🎉")
                .font(.system(size: 56))
            Text("Drop Complete!")
                .font(Theme.serifTitle(28))
            Text("\(outcome.paths.count) balls distributed across your goals")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(summaryRows, id: \.goalID) { row in
                    HStack {
                        Text(row.icon)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.name)
                                .font(.headline)
                            Text("\(row.ballCount) balls · +\(Theme.currency(row.amount))")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        Text("+\(Theme.currency(row.amount))")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(row.amount > 0 ? Theme.successGreen : Theme.textMuted)
                    }
                    .cardStyle(padding: 14)
                }
            }

            PrimaryButton(title: "Transfer Money", action: onTransfer)
            PrimaryButton(title: "Done", style: .secondary, action: onDone)
        }
        .padding()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var summaryRows: [(goalID: UUID, name: String, icon: String, ballCount: Int, amount: Double)] {
        outcome.allocations.map { goalID, amount in
            let goal = goals.first { $0.id == goalID }
            let ballCount = outcome.paths.filter { path in
                guard path.slotIndex < PlinkoEngine.activeSlots(from: goals).count else { return false }
                return PlinkoEngine.activeSlots(from: goals)[path.slotIndex].goalID == goalID
            }.count
            return (goalID, goal?.name ?? "Goal", goal?.icon ?? "🎯", ballCount, amount)
        }
        .sorted { $0.amount > $1.amount }
    }
}

struct ChallengeSheet: View {
    let challenge: Challenge
    let goalName: String
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🎯")
                .font(.system(size: 56))
            Text("Jackpot!")
                .font(Theme.serifTitle(28))
            Text(challenge.challengeDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textBrown)
            Text("Reward: \(Theme.currency(challenge.rewardAmount)) to \(goalName)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.goldDark)

            PrimaryButton(title: "Accept Challenge", action: onAccept)
            PrimaryButton(title: "Not Now", style: .secondary, action: onDecline)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}

struct ChallengeConfirmSheet: View {
    let challenge: Challenge
    let goalName: String
    let onConfirm: () -> Void
    let onFail: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Challenge Check-In")
                .font(Theme.serifTitle(24))
            Text(challenge.conditionText)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textMuted)
            Text("Did you stay disciplined for 3 days?")
                .font(.headline)

            PrimaryButton(title: "Yes — Claim \(Theme.currency(challenge.rewardAmount))", action: onConfirm)
            Button("I didn't make it", role: .destructive, action: onFail)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
