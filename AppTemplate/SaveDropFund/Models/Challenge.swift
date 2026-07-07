import Foundation
import SwiftData

@Model
final class Challenge {
    var id: UUID
    var typeRaw: String
    var challengeDescription: String
    var createdAt: Date
    var dueDate: Date
    var statusRaw: String
    var rewardAmount: Double
    var linkedGoalID: UUID?
    var conditionText: String

    init(
        id: UUID = UUID(),
        type: String = "jackpot",
        challengeDescription: String,
        createdAt: Date = .now,
        dueDate: Date,
        status: ChallengeStatus = .pending,
        rewardAmount: Double,
        linkedGoalID: UUID?,
        conditionText: String
    ) {
        self.id = id
        self.typeRaw = type
        self.challengeDescription = challengeDescription
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.statusRaw = status.rawValue
        self.rewardAmount = rewardAmount
        self.linkedGoalID = linkedGoalID
        self.conditionText = conditionText
    }

    var status: ChallengeStatus {
        get { ChallengeStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var isDue: Bool { Date.now >= dueDate }
}
