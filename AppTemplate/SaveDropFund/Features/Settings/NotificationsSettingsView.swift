import SwiftUI

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferences: [NotificationPreferenceKey: Bool] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(NotificationPreferenceKey.allCases, id: \.rawValue) { key in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.title)
                                .font(.headline)
                            Text(key.subtitle)
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        Toggle("", isOn: binding(for: key))
                            .labelsHidden()
                            .tint(Theme.gold)
                    }
                    .cardStyle(padding: 16)
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
                Text("Notifications")
                    .font(Theme.serifTitle(20))
            }
        }
        .onAppear {
            for key in NotificationPreferenceKey.allCases {
                preferences[key] = NotificationPreferences.isEnabled(key)
            }
        }
    }

    private func binding(for key: NotificationPreferenceKey) -> Binding<Bool> {
        Binding(
            get: { preferences[key] ?? key.defaultValue },
            set: { newValue in
                preferences[key] = newValue
                NotificationPreferences.setEnabled(newValue, for: key)
                if newValue {
                    switch key {
                    case .dropReminders: NotificationScheduler.scheduleDropReminder()
                    case .weeklySummary: NotificationScheduler.scheduleWeeklySummary()
                    default: break
                    }
                }
            }
        )
    }
}
