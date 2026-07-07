import Foundation
import SwiftData

@Model
final class Deposit {
    var id: UUID
    var amount: Double
    var sourceTag: String
    var ballValue: Double
    var ballCount: Int
    var date: Date
    var isAllocated: Bool

    init(
        id: UUID = UUID(),
        amount: Double,
        sourceTag: String,
        ballValue: Double,
        ballCount: Int,
        date: Date = .now,
        isAllocated: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.sourceTag = sourceTag
        self.ballValue = ballValue
        self.ballCount = ballCount
        self.date = date
        self.isAllocated = isAllocated
    }
}

enum DepositCalculator {
    static let ballValues: [Double] = [1, 2, 5, 10]
    static let sourceTags = ["Salary", "Cashback", "Skipped Coffee", "Bonus", "Side Hustle"]

    static func ballCount(amount: Double, ballValue: Double) -> Int {
        guard ballValue > 0, amount > 0 else { return 0 }
        return Int(amount / ballValue)
    }
}
