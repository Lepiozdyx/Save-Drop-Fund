import SwiftData
import SwiftUI

@Observable
@MainActor
final class GoalsViewModel {
    var filter: GoalFilter = .all
    var showingNewGoal = false

    func filteredGoals(_ goals: [Goal]) -> [Goal] {
        switch filter {
        case .all: goals.filter { $0.status != .completed }
        case .active: goals.filter { $0.status == .active }
        case .paused: goals.filter { $0.status == .paused }
        case .completed: goals.filter { $0.status == .completed }
        }
    }
}

struct GoalsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.slotIndex) private var goals: [Goal]
    @State private var viewModel = GoalsViewModel()
    @State private var showingHallOfFame = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.horizontal)

                    FilterChipRow(selection: $viewModel.filter)

                    Group {
                        let filtered = viewModel.filteredGoals(goals)
                        if filtered.isEmpty {
                            EmptyStateView(
                                icon: "🎯",
                                title: "No Goals Yet",
                                message: "Create your first savings goal to start playing."
                            )
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(filtered) { goal in
                                    NavigationLink {
                                        GoalDetailView(goal: goal)
                                    } label: {
                                        GoalCardView(goal: goal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button {
                            showingHallOfFame = true
                        } label: {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(Theme.gold)
                                Text("View Hall of Fame")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textBrown)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [Theme.cream, .white], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .appBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingNewGoal) {
                GoalFormView(mode: .create)
            }
            .sheet(isPresented: $showingHallOfFame) {
                NavigationStack {
                    HallOfFameView()
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("My Goals")
                .font(Theme.serifTitle(32))
                .foregroundStyle(Theme.textBrown)
            Spacer()
            Button {
                viewModel.showingNewGoal = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Theme.gold)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Add goal")
        }
    }
}
