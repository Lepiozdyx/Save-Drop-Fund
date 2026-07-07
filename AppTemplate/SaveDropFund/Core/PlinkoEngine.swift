import Foundation

struct PlinkoSlot: Identifiable {
    let id: UUID
    let goalID: UUID
    let name: String
    let icon: String
    let index: Int
    let placement: SlotPlacement
}

struct PlinkoBallPath {
    let ballIndex: Int
    let slotIndex: Int
    let columnPositions: [Int]
    let amount: Double
    let isJackpot: Bool
}

struct PlinkoDropOutcome {
    let paths: [PlinkoBallPath]
    let allocations: [UUID: Double]
    let slotHitCounts: [Int: Int]
    let jackpotBall: PlinkoBallPath?
    let bonusMultiplier: Double
}

struct PlinkoEngine {
    static let minSlots = 3
    static let maxSlots = 7
    static let rowCount = 8
    static let jackpotProbability = 0.03

    static func activeSlots(from goals: [Goal]) -> [PlinkoSlot] {
        let active = goals.filter { $0.status == .active }.sorted { $0.slotIndex < $1.slotIndex }
        let limited = Array(active.prefix(maxSlots))
        guard limited.count >= minSlots else { return [] }
        return limited.enumerated().map { index, goal in
            PlinkoSlot(
                id: goal.id,
                goalID: goal.id,
                name: goal.name,
                icon: goal.icon,
                index: index,
                placement: goal.slotPlacement
            )
        }
    }

    static func slotWeights(
        slotCount: Int,
        risk: RiskLevel,
        slots: [PlinkoSlot],
        goals: [Goal],
        installedUpgrades: Set<UpgradeEffectType>
    ) -> [Double] {
        guard slotCount > 0 else { return [] }
        let center = Double(slotCount - 1) / 2.0
        var weights: [Double] = (0..<slotCount).map { index in
            let distance = abs(Double(index) - center)
            switch risk {
            case .low:
                return exp(-pow(distance, 2) / 0.8)
            case .balanced:
                return exp(-pow(distance, 2) / 2.0)
            case .high:
                if distance < 1.0 { return 0.05 }
                return 1.0 + (distance * 0.5)
            }
        }

        for (index, slot) in slots.enumerated() {
            if slot.placement == .edge, risk == .high {
                weights[index] *= 2.0
            }
        }

        if installedUpgrades.contains(.magnet),
           let nearestGoal = goals.filter({ $0.status == .active }).min(by: { $0.progress > $1.progress }),
           let slotIndex = slots.firstIndex(where: { $0.goalID == nearestGoal.id }) {
            weights[slotIndex] *= 2.5
        }

        let total = weights.reduce(0, +)
        guard total > 0 else { return Array(repeating: 1.0 / Double(slotCount), count: slotCount) }
        return weights.map { $0 / total }
    }

    static func sampleSlotIndex(weights: [Double], rng: inout some RandomNumberGenerator) -> Int {
        let roll = Double.random(in: 0..<1, using: &rng)
        var cumulative = 0.0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if roll <= cumulative { return index }
        }
        return weights.count - 1
    }

    static func generatePath(to slotIndex: Int, slotCount: Int, rng: inout some RandomNumberGenerator) -> [Int] {
        var positions: [Int] = [slotCount / 2]
        var current = positions[0]

        for row in 1..<rowCount {
            let remainingRows = rowCount - row
            let target = slotIndex
            let bias: Int
            if current < target {
                bias = Int.random(in: 0...2, using: &rng) >= 1 ? 1 : 0
            } else if current > target {
                bias = Int.random(in: 0...2, using: &rng) >= 1 ? -1 : 0
            } else {
                bias = [-1, 0, 1].randomElement(using: &rng) ?? 0
            }

            if row + remainingRows <= rowCount, abs(target - current) > remainingRows {
                current += target > current ? 1 : -1
            } else {
                current = max(0, min(slotCount - 1, current + bias))
            }
            positions.append(current)
        }

        positions[positions.count - 1] = slotIndex
        return positions
    }

    static func simulateDrop(
        goals: [Goal],
        ballCount: Int,
        ballValue: Double,
        risk: RiskLevel,
        installedUpgrades: Set<UpgradeEffectType>
    ) -> PlinkoDropOutcome? {
        var rng = SystemRandomNumberGenerator()
        return simulateDrop(
            goals: goals,
            ballCount: ballCount,
            ballValue: ballValue,
            risk: risk,
            installedUpgrades: installedUpgrades,
            rng: &rng
        )
    }

    static func simulateDrop(
        goals: [Goal],
        ballCount: Int,
        ballValue: Double,
        risk: RiskLevel,
        installedUpgrades: Set<UpgradeEffectType>,
        rng: inout some RandomNumberGenerator
    ) -> PlinkoDropOutcome? {
        let slots = activeSlots(from: goals)
        guard !slots.isEmpty, ballCount > 0, ballValue > 0 else { return nil }

        let effectiveBallCount: Int
        if installedUpgrades.contains(.stormDrop) {
            effectiveBallCount = ballCount + Int(Double(ballCount) * 0.5)
        } else {
            effectiveBallCount = ballCount
        }

        let slotCount = slots.count
        let weights = slotWeights(
            slotCount: slotCount,
            risk: risk,
            slots: slots,
            goals: goals,
            installedUpgrades: installedUpgrades
        )

        var paths: [PlinkoBallPath] = []
        var allocations: [UUID: Double] = [:]
        var slotHitCounts: [Int: Int] = [:]
        var jackpotBall: PlinkoBallPath?
        var bonusMultiplier = 1.0

        for ballIndex in 0..<effectiveBallCount {
            let slotIndex = sampleSlotIndex(weights: weights, rng: &rng)
            let columnPositions = generatePath(to: slotIndex, slotCount: slotCount, rng: &rng)
            let goalID = slots[slotIndex].goalID
            var amount = ballValue

            let isJackpot = Double.random(in: 0..<1, using: &rng) < jackpotProbability
            if isJackpot {
                amount *= 2
                bonusMultiplier = 2
            }

            if installedUpgrades.contains(.multiplier),
               slots[slotIndex].placement == .edge || risk == .high {
                amount *= 2
            }

            if installedUpgrades.contains(.luckyPeg),
               Double.random(in: 0..<1, using: &rng) < 0.08 {
                amount *= 1.0 + Double.random(in: 0.10...0.25, using: &rng)
            }

            let path = PlinkoBallPath(
                ballIndex: ballIndex,
                slotIndex: slotIndex,
                columnPositions: columnPositions,
                amount: amount,
                isJackpot: isJackpot
            )
            paths.append(path)
            allocations[goalID, default: 0] += amount
            slotHitCounts[slotIndex, default: 0] += 1

            if isJackpot, jackpotBall == nil {
                jackpotBall = path
            }
        }

        return PlinkoDropOutcome(
            paths: paths,
            allocations: allocations,
            slotHitCounts: slotHitCounts,
            jackpotBall: jackpotBall,
            bonusMultiplier: bonusMultiplier
        )
    }
}

extension RandomNumberGenerator {
    mutating func randomElement<T>(from collection: [T]) -> T? {
        guard !collection.isEmpty else { return nil }
        let index = Int.random(in: 0..<collection.count, using: &self)
        return collection[index]
    }
}
