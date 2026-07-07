import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var freeBalance: Double
    var points: Int
    var streakCount: Int
    var lastDropDate: Date?
    var pendingBallCount: Int
    var pendingBallValue: Double
    var totalBallsDropped: Int
    var selectedRiskLevelRaw: String

    init(
        id: UUID = UUID(),
        freeBalance: Double = 0,
        points: Int = 0,
        streakCount: Int = 0,
        lastDropDate: Date? = nil,
        pendingBallCount: Int = 0,
        pendingBallValue: Double = 2,
        totalBallsDropped: Int = 0,
        selectedRiskLevel: RiskLevel = .balanced
    ) {
        self.id = id
        self.freeBalance = freeBalance
        self.points = points
        self.streakCount = streakCount
        self.lastDropDate = lastDropDate
        self.pendingBallCount = pendingBallCount
        self.pendingBallValue = pendingBallValue
        self.totalBallsDropped = totalBallsDropped
        self.selectedRiskLevelRaw = selectedRiskLevel.rawValue
    }

    var selectedRiskLevel: RiskLevel {
        get { RiskLevel(rawValue: selectedRiskLevelRaw) ?? .balanced }
        set { selectedRiskLevelRaw = newValue.rawValue }
    }

    var totalSaved: Double { freeBalance }

    var hasBallsReady: Bool { pendingBallCount > 0 }

    func addPendingBalls(count: Int, value: Double, depositAmount: Double) {
        pendingBallCount += count
        pendingBallValue = value
        freeBalance += depositAmount
    }

    func consumeBalls() -> (count: Int, value: Double) {
        let count = pendingBallCount
        let value = pendingBallValue
        pendingBallCount = 0
        return (count, value)
    }

    func updateStreak() {
        let calendar = Calendar.current
        if let last = lastDropDate, calendar.isDateInYesterday(last) {
            streakCount += 1
        } else if let last = lastDropDate, calendar.isDateInToday(last) {
            // same day, keep streak
        } else {
            streakCount = max(streakCount, 1)
        }
        lastDropDate = .now
    }
}
