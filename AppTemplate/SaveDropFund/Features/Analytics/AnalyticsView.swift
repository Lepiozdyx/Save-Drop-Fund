import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @Query(sort: \Goal.currentAmount, order: .reverse) private var goals: [Goal]
    @Query(sort: \Deposit.date) private var deposits: [Deposit]
    @Query(sort: \DropResult.date) private var dropResults: [DropResult]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var activeGoals: [Goal] { goals.filter { $0.status == .active } }
    private var hasProgress: Bool { !goals.isEmpty || !deposits.isEmpty || !dropResults.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Analytics")
                        .font(Theme.serifTitle(32))
                        .foregroundStyle(Theme.textBrown)
                        .padding(.horizontal)

                    if hasProgress {
                        Group {
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "Total Saved",
                                    value: Theme.currency(totalSaved),
                                    icon: "dollarsign.circle.fill"
                                )
                                StatCard(
                                    title: "Balls Dropped",
                                    value: "\(profile?.totalBallsDropped ?? 0)",
                                    icon: "circle.fill"
                                )
                                StatCard(
                                    title: "Goals Active",
                                    value: "\(activeGoals.count)",
                                    icon: "target"
                                )
                            }

                            monthlyDepositsCard
                            savingsTrendCard
                            goalDistributionCard
                            heatmapCard
                        }
                        .padding(.horizontal)

                        achievementsSection
                    } else {
                        EmptyAnalyticsView()
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .appBackground()
            .navigationBarHidden(true)
        }
    }

    private var totalSaved: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }

    private var monthlyDepositsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Deposits")
                .font(.headline)
            Chart(monthlyData, id: \.month) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(item.isCurrent ? Theme.gold : Theme.cream)
                .cornerRadius(6)
            }
            .frame(height: 180)
        }
        .cardStyle()
    }

    private var savingsTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Trend")
                .font(.headline)
            Chart(weeklyTrend, id: \.week) { item in
                LineMark(
                    x: .value("Week", item.week),
                    y: .value("Saved", item.amount)
                )
                .foregroundStyle(Theme.gold)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Week", item.week),
                    y: .value("Saved", item.amount)
                )
                .foregroundStyle(Theme.goldDark)
            }
            .frame(height: 160)
        }
        .cardStyle()
    }

    private var goalDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Distribution")
                .font(.headline)
            HStack {
                Chart(activeGoals) { goal in
                    SectorMark(
                        angle: .value("Amount", goal.currentAmount),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(goal.accentColor)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(activeGoals.prefix(5)) { goal in
                        HStack {
                            Circle()
                                .fill(goal.accentColor)
                                .frame(width: 8, height: 8)
                            Text(goal.name)
                                .font(.caption)
                            Spacer()
                            Text(Theme.currency(goal.currentAmount))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(goal.name == fastestGrowingGoal?.name ? Theme.successGreen : .primary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Board Heatmap")
                .font(.headline)
            HeatmapView(slotHitCounts: aggregatedSlotHits)
                .frame(height: 120)
        }
        .cardStyle()
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    achievementBadge(title: "First Drop", icon: "🎯", unlocked: !dropResults.isEmpty)
                    achievementBadge(
                        title: "7-Day Streak",
                        icon: "🔥",
                        unlocked: (profile?.streakCount ?? 0) >= 7
                    )
                    if let fastest = fastestGrowingGoal {
                        achievementBadge(title: "Rising Star", icon: "🏆", subtitle: fastest.name, unlocked: true)
                    }
                    achievementBadge(
                        title: "Ball Master",
                        icon: "⚪️",
                        subtitle: "\(profile?.totalBallsDropped ?? 0) dropped",
                        unlocked: (profile?.totalBallsDropped ?? 0) >= 100
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    private func achievementBadge(title: String, icon: String, subtitle: String? = nil, unlocked: Bool) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title)
            Text(title)
                .font(.caption.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(width: 110, height: 100)
        .background(unlocked ? .white : Theme.cream.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(unlocked ? 1 : 0.5)
    }

    private var monthlyData: [(month: String, amount: Double, isCurrent: Bool)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: .now)

        return (0..<6).map { offset in
            let date = calendar.date(byAdding: .month, value: -(5 - offset), to: .now) ?? .now
            let month = formatter.string(from: date)
            let monthNumber = calendar.component(.month, from: date)
            let amount = deposits
                .filter { calendar.component(.month, from: $0.date) == monthNumber }
                .reduce(0) { $0 + $1.amount }
            return (month, amount, monthNumber == currentMonth)
        }
    }

    private var weeklyTrend: [(week: String, amount: Double)] {
        var cumulative = 0.0
        return (1...5).map { week in
            let weekDeposits = deposits.prefix(week * 2)
            cumulative = weekDeposits.reduce(0) { $0 + $1.amount }
            return ("W\(week)", cumulative)
        }
    }

    private var aggregatedSlotHits: [Int: Int] {
        dropResults.reduce(into: [:]) { result, drop in
            for (slot, count) in drop.slotHitCounts {
                result[slot, default: 0] += count
            }
        }
    }

    private var fastestGrowingGoal: Goal? {
        activeGoals.max(by: { $0.progress < $1.progress })
    }
}

struct HeatmapView: View {
    let slotHitCounts: [Int: Int]

    var body: some View {
        Canvas { context, size in
            let maxSlot = slotHitCounts.keys.max() ?? 6
            let slotCount = max(maxSlot + 1, 3)
            let cellWidth = size.width / CGFloat(slotCount)
            let maxCount = max(slotHitCounts.values.max() ?? 1, 1)

            for slot in 0..<slotCount {
                let count = slotHitCounts[slot] ?? 0
                let intensity = Double(count) / Double(maxCount)
                let rect = CGRect(x: cellWidth * CGFloat(slot) + 2, y: 8, width: cellWidth - 4, height: size.height - 16)
                let color = Theme.gold.opacity(0.15 + intensity * 0.85)
                context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(color))

                context.draw(
                    Text("\(count)").font(.caption2.weight(.bold)),
                    at: CGPoint(x: rect.midX, y: rect.midY)
                )
            }
        }
    }
}
