import SpriteKit
import SwiftUI

struct PlinkoDropModal: View {
    private static let maxAnimatedBalls = 24

    let slots: [PlinkoSlot]
    let outcome: PlinkoDropOutcome
    let goldenBalls: Bool
    let silverTrail: Bool
    let onFinished: () -> Void

    @State private var scene: PlinkoScene?
    @State private var hasFinished = false

    private var animatedPaths: [PlinkoBallPath] {
        let paths = outcome.paths
        guard paths.count > Self.maxAnimatedBalls else { return paths }
        let step = Double(paths.count) / Double(Self.maxAnimatedBalls)
        return (0..<Self.maxAnimatedBalls).map { index in
            let original = paths[Int(Double(index) * step)]
            return PlinkoBallPath(
                ballIndex: index,
                slotIndex: original.slotIndex,
                columnPositions: original.columnPositions,
                amount: original.amount,
                isJackpot: original.isJackpot
            )
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dropping your balls…")
                    .font(Theme.serifTitle(22))
                    .foregroundStyle(Theme.textBrown)

                Spacer()

                Button {
                    finishDrop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.textMuted)
                }
                .accessibilityLabel("Skip animation")
            }
            .padding(.horizontal)

            GeometryReader { geo in
                Group {
                    if let scene {
                        SpriteView(scene: scene)
                    } else {
                        Color.clear
                            .onAppear {
                                let newScene = PlinkoScene(
                                    size: geo.size,
                                    slots: slots,
                                    paths: animatedPaths,
                                    goldenBalls: goldenBalls,
                                    silverTrail: silverTrail
                                )
                                newScene.onAllBallsLanded = {
                                    finishDrop()
                                }
                                scene = newScene
                            }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal)
        }
        .padding(.vertical)
        .appBackground()
    }

    private func finishDrop() {
        guard !hasFinished else { return }
        hasFinished = true
        scene?.forceFinish()
        onFinished()
    }
}
