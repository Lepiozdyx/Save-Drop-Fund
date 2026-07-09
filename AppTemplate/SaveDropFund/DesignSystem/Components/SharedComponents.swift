import SwiftUI

struct PrimaryButton: View {
    let title: String
    var style: Style = .gold
    var isEnabled: Bool = true
    let action: () -> Void

    enum Style {
        case gold
        case green
        case secondary
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
    }

    private var foregroundColor: Color {
        switch style {
        case .gold: .black
        case .green: .white
        case .secondary: Theme.textBrown
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .gold:
            LinearGradient(colors: [Theme.gold, Theme.goldDark], startPoint: .leading, endPoint: .trailing)
        case .green:
            Theme.successGreen
        case .secondary:
            Theme.cream
        }
    }
}

struct ProgressBarView: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.08))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

struct StatChip: View {
    let icon: String
    let text: String
    var iconColor: Color = Theme.gold

    var body: some View {
        HStack(spacing: 4) {
            if icon.count <= 2 && !icon.contains(".") {
                Text(icon)
            } else {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

struct RiskSelector: View {
    @Binding var selection: RiskLevel

    var body: some View {
        Picker("Risk Level", selection: $selection) {
            ForEach(RiskLevel.allCases) { level in
                Text(level.title).tag(level)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct FilterChipRow: View {
    @Binding var selection: GoalFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GoalFilter.allCases) { filter in
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection == filter ? Theme.gold : Theme.cream)
                            .foregroundStyle(selection == filter ? .black : Theme.textBrown)
                            .clipShape(Capsule())
                    }
                    .accessibilityAddTraits(selection == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }
}

struct GoalCardView: View {
    let goal: Goal
    var showsChevron: Bool = true
    var showsStatus: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            Text(goal.icon)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(goal.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if showsStatus {
                        Text(goal.status.title)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .foregroundStyle(statusColor)
                            .clipShape(Capsule())
                    }
                }

                Text("\(Theme.currency(goal.currentAmount)) of \(Theme.currency(goal.targetAmount))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)

                ProgressBarView(progress: goal.progress, color: goal.accentColor)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name), \(goal.progressPercent) percent complete")
    }

    private var statusColor: Color {
        switch goal.status {
        case .active: Theme.successGreen
        case .paused: Theme.textMuted
        case .completed: Theme.gold
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Theme.gold)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
    }
}

struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<24 {
                    let x = size.width * CGFloat((Double(index) * 0.07).truncatingRemainder(dividingBy: 1))
                    let y = CGFloat(sin(time + Double(index)) * 20 + Double(index) * 12).truncatingRemainder(dividingBy: size.height)
                    let rect = CGRect(x: x, y: y, width: 6, height: 6)
                    context.fill(Path(ellipseIn: rect), with: .color(confettiColor(index)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func confettiColor(_ index: Int) -> Color {
        [Theme.gold, Theme.successGreen, .pink, .orange, .purple][index % 5]
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 48))
            Text(title)
                .font(Theme.serifTitle(22))
                .foregroundStyle(Theme.textBrown)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct EmptyAnalyticsView: View {
    var body: some View {
        EmptyStateView(
            icon: "📊",
            title: "No Analytics Yet",
            message: "Once you start saving and dropping balls, your trends, charts, and achievements will show up here."
        )
        .padding(.top, 60)
    }
}

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textBrown)
                .frame(width: 40, height: 40)
        }
        .accessibilityLabel("Back")
    }
}
