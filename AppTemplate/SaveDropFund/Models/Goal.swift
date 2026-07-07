import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Goal {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var icon: String
    var colorHex: String
    var slotPlacementRaw: String
    var slotIndex: Int
    var statusRaw: String
    var notes: String
    var riskLevelRaw: String
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        icon: String = "✈️",
        colorHex: String = "#F2BF33",
        slotPlacement: SlotPlacement = .center,
        slotIndex: Int = 0,
        status: GoalStatus = .active,
        notes: String = "",
        riskLevel: RiskLevel = .balanced,
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.icon = icon
        self.colorHex = colorHex
        self.slotPlacementRaw = slotPlacement.rawValue
        self.slotIndex = slotIndex
        self.statusRaw = status.rawValue
        self.notes = notes
        self.riskLevelRaw = riskLevel.rawValue
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var slotPlacement: SlotPlacement {
        get { SlotPlacement(rawValue: slotPlacementRaw) ?? .center }
        set { slotPlacementRaw = newValue.rawValue }
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var riskLevel: RiskLevel {
        get { RiskLevel(rawValue: riskLevelRaw) ?? .balanced }
        set { riskLevelRaw = newValue.rawValue }
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1)
    }

    var progressPercent: Int {
        Int((progress * 100).rounded())
    }

    var accentColor: Color {
        Color(hex: colorHex) ?? Theme.gold
    }

    var isActive: Bool { status == .active }

    func markCompletedIfNeeded() {
        if currentAmount >= targetAmount, status != .completed {
            status = .completed
            completedAt = .now
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6, let int = UInt64(hexSanitized, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#F2BF33"
        }
        return String(format: "#%02X%02X%02X", Int(components[0] * 255), Int(components[1] * 255), Int(components[2] * 255))
    }
}
