import SwiftData
import SwiftUI

@Observable
@MainActor
final class DepositViewModel {
    var amountText = "60"
    var selectedBallValue: Double = 2
    var selectedSource = DepositCalculator.sourceTags[0]
    var didConvert = false

    var amount: Double { Double(amountText) ?? 0 }
    var ballCount: Int { DepositCalculator.ballCount(amount: amount, ballValue: selectedBallValue) }
    var canConvert: Bool { ballCount > 0 }

    func resetAfterConvert() {
        didConvert = false
    }
}

struct DepositView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Binding var selectedTab: AppTab
    @State private var viewModel = DepositViewModel()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Load Balls")
                                .font(Theme.serifTitle(32))
                                .foregroundStyle(Theme.textBrown)
                            Text("Convert your savings into drops")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textMuted)
                        }

                        summaryCard

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deposit Amount ($)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textBrown)
                            TextField("60", text: $viewModel.amountText)
                                .keyboardType(.decimalPad)
                                .font(.title.weight(.bold))
                                .padding()
                                .background(Theme.cream)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ball Value ($ per ball)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textBrown)
                            HStack(spacing: 8) {
                                ForEach(DepositCalculator.ballValues, id: \.self) { value in
                                    Button("$\(Int(value))") {
                                        viewModel.selectedBallValue = value
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.selectedBallValue == value ? Theme.gold : Theme.cream)
                                    .foregroundStyle(viewModel.selectedBallValue == value ? .black : Theme.textMuted)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Savings Source")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textBrown)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DepositCalculator.sourceTags, id: \.self) { tag in
                                    Button(tag) {
                                        viewModel.selectedSource = tag
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(viewModel.selectedSource == tag ? Theme.gold : Theme.cream)
                                    .foregroundStyle(viewModel.selectedSource == tag ? .black : Theme.textMuted)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    PrimaryButton(
                        title: viewModel.didConvert ? "✓ Converted! Heading to board..." : "Convert $\(Int(viewModel.amount)) → \(viewModel.ballCount) Balls",
                        style: viewModel.didConvert ? .green : .gold,
                        isEnabled: viewModel.canConvert
                    ) {
                        convert()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .appBackground()
            .keyboardDismissToolbar()
            .navigationBarHidden(true)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$\(Int(viewModel.amount))")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("→")
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(viewModel.ballCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.gold)
                Text("balls")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 4) {
                ForEach(0..<min(viewModel.ballCount, 12), id: \.self) { index in
                    Circle()
                        .fill(index % 2 == 0 ? Theme.gold : .white.opacity(0.4))
                        .frame(width: 10, height: 10)
                }
                if viewModel.ballCount > 12 {
                    Text("+\(viewModel.ballCount - 12)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.gold)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.cardBrown, Theme.cardBrownLight], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func convert() {
        guard viewModel.canConvert else { return }

        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()

        let deposit = Deposit(
            amount: viewModel.amount,
            sourceTag: viewModel.selectedSource,
            ballValue: viewModel.selectedBallValue,
            ballCount: viewModel.ballCount
        )
        modelContext.insert(deposit)
        profile.addPendingBalls(count: viewModel.ballCount, value: viewModel.selectedBallValue, depositAmount: viewModel.amount)
        try? modelContext.save()

        viewModel.didConvert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            selectedTab = .home
            viewModel.resetAfterConvert()
        }
    }
}
