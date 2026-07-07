import Foundation
import SwiftData

@Model
final class Upgrade {
    var id: String
    var name: String
    var upgradeDescription: String
    var cost: Int
    var iconName: String
    var isInstalled: Bool
    var effectTypeRaw: String

    init(
        id: String,
        name: String,
        upgradeDescription: String,
        cost: Int,
        iconName: String,
        isInstalled: Bool = false,
        effectType: UpgradeEffectType
    ) {
        self.id = id
        self.name = name
        self.upgradeDescription = upgradeDescription
        self.cost = cost
        self.iconName = iconName
        self.isInstalled = isInstalled
        self.effectTypeRaw = effectType.rawValue
    }

    var effectType: UpgradeEffectType {
        UpgradeEffectType(rawValue: effectTypeRaw) ?? .multiplier
    }

    static func catalog() -> [Upgrade] {
        [
            Upgrade(
                id: "multiplier",
                name: "x2 Multiplier Peg",
                upgradeDescription: "Double the impact of every ball that lands on this peg. Works on all active goals.",
                cost: 5000,
                iconName: "⚡",
                effectType: .multiplier
            ),
            Upgrade(
                id: "magnet",
                name: "Goal Magnet",
                upgradeDescription: "Attracts balls toward your nearest-complete goal, accelerating your progress.",
                cost: 6000,
                iconName: "🧲",
                isInstalled: false,
                effectType: .magnet
            ),
            Upgrade(
                id: "golden",
                name: "Golden Balls",
                upgradeDescription: "All balls render in luxurious gold with a specular metallic finish.",
                cost: 4000,
                iconName: "✨",
                effectType: .golden
            ),
            Upgrade(
                id: "silverTrail",
                name: "Silver Trail",
                upgradeDescription: "Each ball leaves a beautiful particle trail as it falls through the board.",
                cost: 3500,
                iconName: "💫",
                effectType: .silverTrail
            ),
            Upgrade(
                id: "luckyPeg",
                name: "Lucky Peg",
                upgradeDescription: "A special peg that awards a random 10–25% savings bonus on contact.",
                cost: 8000,
                iconName: "🍀",
                effectType: .luckyPeg
            ),
            Upgrade(
                id: "stormDrop",
                name: "Storm Drop",
                upgradeDescription: "Release 50% more balls per drop for a full session of high-energy savings.",
                cost: 2200,
                iconName: "⛈️",
                effectType: .stormDrop
            )
        ]
    }
}
