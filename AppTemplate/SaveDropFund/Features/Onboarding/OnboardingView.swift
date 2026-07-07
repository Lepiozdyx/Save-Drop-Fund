import SwiftUI

private struct OnboardingPage {
    let image: String
    let title: String
    let subtitle: String
    let background: LinearGradient
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(page.image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 40)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text(page.title)
                    .font(Theme.serifTitle(32))
                    .foregroundStyle(Theme.textBrown)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(page.background.ignoresSafeArea())
    }
}

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var selection = 0

    private static let mintBackground = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.98, blue: 0.95),
            Color(red: 0.88, green: 0.96, blue: 0.92)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private static let creamBackground = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.98, blue: 0.94),
            Color(red: 0.98, green: 0.96, blue: 0.88)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private static let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "ob1",
            title: "Save Money Like Never Before",
            subtitle: "Turn your savings into a fun, rewarding experience.",
            background: Theme.backgroundGradient
        ),
        OnboardingPage(
            image: "ob2",
            title: "Every Ball Finds a Purpose",
            subtitle: "Every drop automatically distributes savings toward your goals.",
            background: mintBackground
        ),
        OnboardingPage(
            image: "ob3",
            title: "Choose Your Strategy",
            subtitle: "Pick from Low Risk, Balanced, or High Risk to shape how your savings flow.",
            background: Theme.backgroundGradient
        ),
        OnboardingPage(
            image: "ob4",
            title: "Watch Your Dreams Fill Up",
            subtitle: "Play. Save. Achieve. Every goal unlocks a golden milestone.",
            background: creamBackground
        )
    ]

    private var isLastPage: Bool {
        selection == Self.pages.count - 1
    }

    private var buttonTitle: String {
        isLastPage ? "Get Started" : "Continue"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $selection) {
                ForEach(Self.pages.indices, id: \.self) { index in
                    OnboardingPageView(page: Self.pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page)

            if !isLastPage {
                Button("Skip", action: onComplete)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 8)
                    .padding(.trailing, 20)
                    .accessibilityLabel("Skip onboarding")
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: buttonTitle) {
                if isLastPage {
                    onComplete()
                } else {
                    withAnimation {
                        selection += 1
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
