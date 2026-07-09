import SwiftData
import SwiftUI

@Observable
@MainActor
final class HomeViewModel {
    var riskLevel: RiskLevel = .balanced
    var isDropping = false
    var showSummary = false
    var showChallenge = false
    var showChallengeConfirm = false
    var lastOutcome: PlinkoDropOutcome?
    var showDropModal = false
    var pendingDropBallCount = 0
    var pendingDropBallValue = 0.0
    var pendingChallenge: Challenge?

    func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning ☀️"
        case 12..<17: return "Good afternoon 🌤️"
        default: return "Good evening 🌙"
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.slotIndex) private var goals: [Goal]
    @Query private var profiles: [UserProfile]
    @Query private var upgrades: [Upgrade]
    @Query(filter: #Predicate<Challenge> { $0.statusRaw == "pending" }) private var pendingChallenges: [Challenge]

    @Binding var selectedTab: AppTab
    @State private var viewModel = HomeViewModel()
    @State private var showingNotifications = false

    private var profile: UserProfile? { profiles.first }
    private var activeGoals: [Goal] { goals.filter { $0.status == .active } }
    private var plinkoSlots: [PlinkoSlot] { PlinkoEngine.activeSlots(from: goals) }
    private var installedEffects: Set<UpgradeEffectType> {
        Set(upgrades.filter(\.isInstalled).map(\.effectType))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        header
                        walletCard
                        RiskSelector(selection: $viewModel.riskLevel)

                        if plinkoSlots.count >= PlinkoEngine.minSlots {
                            Image("сontainer")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                        } else {
                            EmptyStateView(
                                icon: "🎯",
                                title: "Add More Goals",
                                message: "You need at least \(PlinkoEngine.minSlots) active goals to play."
                            )
                            .frame(height: 280)
                            .background(Theme.boardCream)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }

                        dropButton
                    }
                    .padding(.horizontal)

                    goalsPreview
                }
                .padding(.vertical)
            }
            .appBackground()
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $viewModel.showDropModal) {
                if let outcome = viewModel.lastOutcome {
                    PlinkoDropModal(
                        slots: plinkoSlots,
                        outcome: outcome,
                        goldenBalls: installedEffects.contains(.golden),
                        silverTrail: installedEffects.contains(.silverTrail)
                    ) {
                        completeDropAnimation()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSummary, onDismiss: presentPendingChallengeAfterSummary) {
                if let outcome = viewModel.lastOutcome {
                    DropSummarySheet(
                        outcome: outcome,
                        goals: goals,
                        ballValue: profile?.pendingBallValue ?? 2,
                        onTransfer: { viewModel.showSummary = false },
                        onDone: { viewModel.showSummary = false }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showChallenge) {
                if let challenge = viewModel.pendingChallenge {
                    ChallengeSheet(
                        challenge: challenge,
                        goalName: goalName(for: challenge.linkedGoalID),
                        onAccept: acceptChallenge,
                        onDecline: { viewModel.showChallenge = false }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showChallengeConfirm) {
                if let challenge = pendingChallenges.first {
                    ChallengeConfirmSheet(
                        challenge: challenge,
                        goalName: goalName(for: challenge.linkedGoalID),
                        onConfirm: { completeChallenge(challenge, success: true) },
                        onFail: { completeChallenge(challenge, success: false) }
                    )
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NavigationStack {
                    NotificationsSettingsView()
                }
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                if let profile {
                    viewModel.riskLevel = profile.selectedRiskLevel
                }
                if let challenge = pendingChallenges.first, challenge.isDue,
                   !viewModel.showSummary, !viewModel.showChallenge {
                    viewModel.showChallengeConfirm = true
                }
            }
            .onChange(of: viewModel.riskLevel) { _, newValue in
                profile?.selectedRiskLevel = newValue
                try? modelContext.save()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Drop & Fund")
                    .font(Theme.serifTitle(32))
                    .foregroundStyle(Theme.textBrown)
                Text(viewModel.greeting())
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Button { showingNotifications = true } label: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(Theme.textBrown)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Notifications")
        }
    }

    private var walletCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Saved")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(Theme.currency(profile?.freeBalance ?? 0))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                StatChip(icon: "🔥", text: "\(profile?.streakCount ?? 0) Days")
            }

            HStack {
                StatChip(icon: "star.fill", text: "\(profile?.points ?? 0) pts", iconColor: Theme.gold)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                    Text(profile?.hasBallsReady == true ? "\(profile?.pendingBallCount ?? 0) balls ready" : "No balls loaded")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.cardBrown, Theme.cardBrownLight], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var dropButton: some View {
        PrimaryButton(
            title: dropButtonTitle,
            isEnabled: canDrop && !viewModel.isDropping
        ) {
            performDrop()
        }
        .overlay {
            if canDrop && !viewModel.isDropping {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.gold.opacity(0.5), lineWidth: 2)
                    .scaleEffect(1.02)
                    .opacity(0.6)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: canDrop)
            }
        }
    }

    private var dropButtonTitle: String {
        if viewModel.isDropping { return "Dropping..." }
        if canDrop { return "DROP • \(profile?.pendingBallCount ?? 0) balls" }
        return "Load Balls First"
    }

    private var canDrop: Bool {
        (profile?.pendingBallCount ?? 0) > 0 && plinkoSlots.count >= PlinkoEngine.minSlots
    }

    private var goalsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals")
                    .font(Theme.serifTitle(20))
                Spacer()
                Button("See All") { selectedTab = .goals }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.goldDark)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeGoals.prefix(3)) { goal in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(goal.icon)
                                .font(.title2)
                            Text(goal.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(goal.progressPercent)%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(goal.accentColor)
                            ProgressBarView(progress: goal.progress, color: goal.accentColor)
                        }
                        .padding(14)
                        .frame(width: 120)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func performDrop() {
        guard let profile, profile.pendingBallCount > 0 else {
            selectedTab = .deposit
            return
        }

        let ballCount = profile.pendingBallCount
        let ballValue = profile.pendingBallValue
        profile.consumeBalls()

        guard let outcome = PlinkoEngine.simulateDrop(
            goals: goals,
            ballCount: ballCount,
            ballValue: ballValue,
            risk: viewModel.riskLevel,
            installedUpgrades: installedEffects
        ) else { return }

        viewModel.lastOutcome = outcome
        viewModel.pendingDropBallCount = ballCount
        viewModel.pendingDropBallValue = ballValue
        viewModel.isDropping = true
        viewModel.showDropModal = true
    }

    private func completeDropAnimation() {
        guard let outcome = viewModel.lastOutcome else { return }
        applyOutcome(
            outcome,
            ballCount: viewModel.pendingDropBallCount,
            ballValue: viewModel.pendingDropBallValue
        )
        viewModel.showDropModal = false
        viewModel.isDropping = false
        viewModel.showSummary = true
    }

    private func applyOutcome(_ outcome: PlinkoDropOutcome, ballCount: Int, ballValue: Double) {
        guard let profile else { return }

        for (goalID, amount) in outcome.allocations {
            if let goal = goals.first(where: { $0.id == goalID }) {
                let previousPercent = goal.progressPercent
                goal.currentAmount += amount
                goal.markCompletedIfNeeded()

                let newPercent = goal.progressPercent
                for milestone in [25, 50, 75, 100] where previousPercent < milestone && newPercent >= milestone {
                    NotificationScheduler.notifyGoalMilestone(goalName: goal.name, percent: milestone)
                }
            }
        }

        let dropResult = DropResult(
            riskLevel: viewModel.riskLevel,
            ballsDropped: outcome.paths.count,
            ballValue: ballValue,
            allocations: outcome.allocations,
            slotHitCounts: outcome.slotHitCounts
        )
        modelContext.insert(dropResult)

        profile.totalBallsDropped += outcome.paths.count
        profile.points += outcome.paths.count * 5
        profile.updateStreak()

        if let jackpot = outcome.jackpotBall,
           let slot = plinkoSlots[safe: jackpot.slotIndex] {
            let challenge = Challenge(
                challengeDescription: "Double this drop! Find extra savings to confirm the bonus in real life.",
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
                rewardAmount: jackpot.amount,
                linkedGoalID: slot.goalID,
                conditionText: "Don't buy coffee outside home for the next 3 days"
            )
            modelContext.insert(challenge)
            viewModel.pendingChallenge = challenge
            NotificationScheduler.scheduleChallengeReminder(challenge: challenge)
        }

        try? modelContext.save()
    }

    private func presentPendingChallengeAfterSummary() {
        guard viewModel.pendingChallenge != nil else { return }
        viewModel.showChallenge = true
    }

    private func acceptChallenge() {
        viewModel.showChallenge = false
    }

    private func completeChallenge(_ challenge: Challenge, success: Bool) {
        if success, let goalID = challenge.linkedGoalID,
           let goal = goals.first(where: { $0.id == goalID }) {
            goal.currentAmount += challenge.rewardAmount
            goal.markCompletedIfNeeded()
            profile?.points += 100
            challenge.status = .completed
        } else {
            challenge.status = .failed
        }
        viewModel.showChallengeConfirm = false
        try? modelContext.save()
    }

    private func goalName(for id: UUID?) -> String {
        guard let id, let goal = goals.first(where: { $0.id == id }) else { return "your goal" }
        return goal.name
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
