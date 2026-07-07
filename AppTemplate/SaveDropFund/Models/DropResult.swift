import Foundation
import SwiftData

@Model
final class DropResult {
    var id: UUID
    var date: Date
    var riskLevelRaw: String
    var ballsDropped: Int
    var ballValue: Double
    var allocationsData: Data
    var slotHitCountsData: Data

    init(
        id: UUID = UUID(),
        date: Date = .now,
        riskLevel: RiskLevel,
        ballsDropped: Int,
        ballValue: Double,
        allocations: [UUID: Double],
        slotHitCounts: [Int: Int]
    ) {
        self.id = id
        self.date = date
        self.riskLevelRaw = riskLevel.rawValue
        self.ballsDropped = ballsDropped
        self.ballValue = ballValue
        self.allocationsData = (try? JSONEncoder().encode(allocations.mapKeys { $0.uuidString })) ?? Data()
        self.slotHitCountsData = (try? JSONEncoder().encode(slotHitCounts.mapKeys { String($0) })) ?? Data()
    }

    var riskLevel: RiskLevel {
        RiskLevel(rawValue: riskLevelRaw) ?? .balanced
    }

    var allocations: [UUID: Double] {
        guard let dict = try? JSONDecoder().decode([String: Double].self, from: allocationsData) else { return [:] }
        return Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, value)
        })
    }

    var slotHitCounts: [Int: Int] {
        guard let dict = try? JSONDecoder().decode([String: Int].self, from: slotHitCountsData) else { return [:] }
        return Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
            guard let intKey = Int(key) else { return nil }
            return (intKey, value)
        })
    }
}

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}
