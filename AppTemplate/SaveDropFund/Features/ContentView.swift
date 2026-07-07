import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Goal.self,
            Deposit.self,
            DropResult.self,
            Upgrade.self,
            Challenge.self,
            UserProfile.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
                    .onAppear {
                        let context = sharedModelContainer.mainContext
                        DataSeeder.seedIfNeeded(context: context)
                        Task {
                            _ = await NotificationScheduler.requestAuthorization()
                            NotificationScheduler.scheduleDropReminder()
                            NotificationScheduler.scheduleWeeklySummary()
                        }
                    }
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    ContentView()
}
