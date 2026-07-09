import SwiftData
import SwiftUI

struct GoalFormView: View {
    enum Mode {
        case create
        case edit(Goal)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.slotIndex) private var existingGoals: [Goal]

    let mode: Mode

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var notes = ""
    @State private var selectedIcon = "✈️"
    @State private var selectedColor: Color = Theme.accentColors[0]
    @State private var slotPlacement: SlotPlacement = .center
    @State private var riskLevel: RiskLevel = .balanced

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(selectedIcon)
                        .font(.system(size: 64))
                        .padding(.top, 8)
                    Text("Choose an icon below")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)

                    iconGrid

                    formField(title: "Goal Name") {
                        TextField("e.g. Dream Vacation", text: $name)
                            .textFieldStyle(.plain)
                    }

                    formField(title: "Target Amount ($)") {
                        TextField("e.g. 5000", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                    }

                    formField(title: "Notes (optional)") {
                        TextField("What motivates you?", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textBrown)
                        HStack(spacing: 12) {
                            ForEach(Theme.accentColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                                    .onTapGesture { selectedColor = color }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Slot Placement")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textBrown)
                        HStack(spacing: 8) {
                            ForEach(SlotPlacement.allCases) { placement in
                                Button(placement.title) {
                                    slotPlacement = placement
                                }
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(slotPlacement == placement ? Theme.gold : Theme.cream)
                                .foregroundStyle(slotPlacement == placement ? .black : Theme.textMuted)
                                .clipShape(Capsule())
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Risk Level")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.textBrown)
                        RiskSelector(selection: $riskLevel)
                    }

                    PrimaryButton(title: modeTitle, action: save)
                        .padding(.top, 8)
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton { dismiss() }
                }
            }
            .keyboardDismissToolbar()
            .onAppear(perform: loadExisting)
        }
        .presentationDragIndicator(.visible)
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(Theme.goalIcons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Text(icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Theme.cream)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(selectedIcon == icon ? Theme.gold : .clear, lineWidth: 2)
                        )
                }
            }
        }
    }

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textBrown)
            content()
                .padding()
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create: "Create Goal"
        case .edit: "Save Changes"
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .create: "New Goal"
        case .edit: "Goal Details"
        }
    }

    private func loadExisting() {
        guard case .edit(let goal) = mode else { return }
        name = goal.name
        targetAmount = String(format: "%.0f", goal.targetAmount)
        notes = goal.notes
        selectedIcon = goal.icon
        selectedColor = goal.accentColor
        slotPlacement = goal.slotPlacement
        riskLevel = goal.riskLevel
    }

    private func save() {
        guard let amount = Double(targetAmount), amount > 0, !name.isEmpty else { return }

        switch mode {
        case .create:
            let nextIndex = (existingGoals.map(\.slotIndex).max() ?? -1) + 1
            let goal = Goal(
                name: name,
                targetAmount: amount,
                icon: selectedIcon,
                colorHex: selectedColor.hexString,
                slotPlacement: slotPlacement,
                slotIndex: nextIndex,
                notes: notes,
                riskLevel: riskLevel
            )
            modelContext.insert(goal)
        case .edit(let goal):
            goal.name = name
            goal.targetAmount = amount
            goal.icon = selectedIcon
            goal.colorHex = selectedColor.hexString
            goal.slotPlacement = slotPlacement
            goal.notes = notes
            goal.riskLevel = riskLevel
        }

        try? modelContext.save()
        dismiss()
    }
}

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var goal: Goal

    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressCard

                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Name")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textBrown)
                    Text(goal.name)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                infoRow(title: "Target Amount", value: Theme.currency(goal.targetAmount))
                infoRow(title: "Current Saved", value: Theme.currency(goal.currentAmount))

                if !goal.notes.isEmpty {
                    infoRow(title: "Notes", value: goal.notes)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Risk Level")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textBrown)
                    RiskSelector(selection: Binding(
                        get: { goal.riskLevel },
                        set: { goal.riskLevel = $0 }
                    ))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Status")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textBrown)
                    HStack(spacing: 8) {
                        ForEach([GoalStatus.active, .paused], id: \.rawValue) { status in
                            Button(status.title) {
                                goal.status = status
                                try? modelContext.save()
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(goal.status == status ? (status == .active ? Theme.successGreen : Theme.cream) : Theme.cream)
                            .foregroundStyle(goal.status == status ? (status == .active ? .white : Theme.textBrown) : Theme.textMuted)
                            .clipShape(Capsule())
                        }
                    }
                }

                PrimaryButton(title: "Edit Goal") {
                    showingEdit = true
                }

                if goal.status != .completed {
                    Button("Mark as Completed") {
                        goal.currentAmount = goal.targetAmount
                        goal.markCompletedIfNeeded()
                        try? modelContext.save()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.successGreen)
                }

                Button("Delete Goal", role: .destructive) {
                    modelContext.delete(goal)
                    try? modelContext.save()
                    dismiss()
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .appBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text("Goal Details")
                    .font(Theme.serifTitle(20))
            }
        }
        .sheet(isPresented: $showingEdit) {
            GoalFormView(mode: .edit(goal))
        }
    }

    private var progressCard: some View {
        VStack(spacing: 12) {
            Text(goal.icon)
                .font(.system(size: 48))
            Text(goal.name)
                .font(Theme.serifTitle(24))
            Text("\(goal.progressPercent)%")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.gold)
            Text("\(Theme.currency(goal.currentAmount)) of \(Theme.currency(goal.targetAmount))")
                .foregroundStyle(Theme.textMuted)
            ProgressBarView(progress: goal.progress, color: goal.accentColor, height: 10)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textBrown)
            Text(value)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cream)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct HallOfFameView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Goal> { $0.statusRaw == "completed" }, sort: \Goal.completedAt, order: .reverse)
    private var completedGoals: [Goal]

    private var totalSaved: Double {
        completedGoals.reduce(0) { $0 + $1.currentAmount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard

                ForEach(Array(completedGoals.enumerated()), id: \.element.id) { index, goal in
                    HStack(spacing: 14) {
                        ZStack(alignment: .topTrailing) {
                            Text(goal.icon)
                                .font(.title)
                                .frame(width: 52, height: 52)
                                .background(Theme.cream)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(width: 20, height: 20)
                                .background(Theme.gold)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.name)
                                .font(.headline)
                            Text(Theme.currency(goal.currentAmount) + " saved")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(goal.accentColor)
                            if !goal.notes.isEmpty {
                                Text(goal.notes)
                                    .font(.caption)
                                    .italic()
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }

                        Spacer()
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Theme.gold)
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text("Hall of Fame")
                    .font(Theme.serifTitle(20))
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "building.columns.fill")
                .font(.title)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(completedGoals.count) Goals Achieved")
                    .font(Theme.serifTitle(22))
                    .foregroundStyle(.white)
                Text("Total saved: \(Theme.currency(totalSaved))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.cardBrown, Theme.cardBrownLight], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
