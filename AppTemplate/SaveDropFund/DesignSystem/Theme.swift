import SwiftUI
import UIKit

enum Theme {
    static let backgroundPink = Color(red: 0.99, green: 0.89, blue: 0.89)
    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let backgroundTop = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.10, blue: 0.11, alpha: 1)
            : UIColor(red: 1.0, green: 0.97, blue: 0.95, alpha: 1)
    })

    static let backgroundBottom = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.12, blue: 0.14, alpha: 1)
            : UIColor(red: 0.99, green: 0.89, blue: 0.89, alpha: 1)
    })

    static let cardBrown = Color(red: 0.29, green: 0.17, blue: 0.12)
    static let cardBrownLight = Color(red: 0.42, green: 0.28, blue: 0.20)
    static let gold = Color(red: 0.95, green: 0.75, blue: 0.20)
    static let goldDark = Color(red: 0.82, green: 0.62, blue: 0.10)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let textBrown = Color(red: 0.35, green: 0.22, blue: 0.15)
    static let textMuted = Color(red: 0.55, green: 0.45, blue: 0.40)
    static let boardCream = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let successGreen = Color(red: 0.30, green: 0.65, blue: 0.35)

    static let accentColors: [Color] = [
        Color(red: 0.95, green: 0.75, blue: 0.20),
        Color(red: 0.25, green: 0.55, blue: 0.35),
        Color(red: 0.90, green: 0.45, blue: 0.20),
        Color(red: 0.55, green: 0.60, blue: 0.30),
        Color(red: 0.70, green: 0.55, blue: 0.35),
        Color(red: 0.35, green: 0.55, blue: 0.75)
    ]

    static let goalIcons = ["✈️", "🛡️", "💻", "🚗", "💍", "🏠", "📱", "🎓", "🏋️", "🎸", "🌍", "💊"]

    static func serifTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    static func compactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }

    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    /// Adds a "hide keyboard" button to the keyboard toolbar for any focused
    /// text input within this view.
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
    }
}
