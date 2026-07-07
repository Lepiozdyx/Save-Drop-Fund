import Foundation

enum RiskLevel: String, CaseIterable, Identifiable, Codable {
    case low
    case balanced
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .balanced: "Balanced"
        case .high: "High"
        }
    }

    var icon: String {
        switch self {
        case .low: "shield.fill"
        case .balanced: "scale.3d"
        case .high: "rocket.fill"
        }
    }
}

enum GoalStatus: String, CaseIterable, Identifiable, Codable {
    case active
    case paused
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: "Active"
        case .paused: "Paused"
        case .completed: "Completed"
        }
    }
}

enum SlotPlacement: String, CaseIterable, Identifiable, Codable {
    case center
    case edge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .center: "Center"
        case .edge: "Edge"
        }
    }
}

enum UpgradeEffectType: String, CaseIterable, Identifiable, Codable {
    case multiplier
    case magnet
    case golden
    case silverTrail
    case luckyPeg
    case stormDrop

    var id: String { rawValue }
}

enum ChallengeStatus: String, Codable {
    case pending
    case completed
    case failed
}

enum GoalFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case paused
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .active: "Active"
        case .paused: "Paused"
        case .completed: "Completed"
        }
    }
}

enum AppTab: Hashable {
    case home
    case goals
    case deposit
    case shop
    case analytics
}
