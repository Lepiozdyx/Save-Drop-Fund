import SpriteKit
import UIKit

final class PlinkoScene: SKScene, SKPhysicsContactDelegate {
    var onBallLanded: ((Int) -> Void)?
    var onAllBallsLanded: (() -> Void)?

    private let slots: [PlinkoSlot]
    private let paths: [PlinkoBallPath]
    private let goldenBalls: Bool
    private let silverTrail: Bool

    private var pegSpacingX: CGFloat = 0
    private var rowHeight: CGFloat = 0
    private var slotWidth: CGFloat = 0
    private var slotY: CGFloat = 0
    private var landedBallIndices = Set<Int>()
    private var hasFinished = false
    private var safetyTimer: Timer?

    private struct PhysicsCategory {
        static let ball: UInt32 = 1 << 0
        static let peg: UInt32 = 1 << 1
        static let wall: UInt32 = 1 << 2
        static let sensor: UInt32 = 1 << 3
    }

    init(
        size: CGSize,
        slots: [PlinkoSlot],
        paths: [PlinkoBallPath],
        goldenBalls: Bool,
        silverTrail: Bool
    ) {
        self.slots = slots
        self.paths = paths
        self.goldenBalls = goldenBalls
        self.silverTrail = silverTrail
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -18)
        physicsWorld.contactDelegate = self

        let slotCount = max(slots.count, PlinkoEngine.minSlots)
        pegSpacingX = size.width / CGFloat(slotCount + 1)
        rowHeight = (size.height - 40) / CGFloat(PlinkoEngine.rowCount + 1)
        slotWidth = size.width / CGFloat(slotCount)
        slotY = size.height - 24

        addBoundaryWalls()
        addPegs(slotCount: slotCount)
        addSlots(slotCount: slotCount)
        scheduleBallSpawns()

        let timeout = max(6.0, Double(paths.count) * 0.3 + 3.0)
        safetyTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.finishIfNeeded()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        steerBalls()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        guard
            let ballBody = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.ball }),
            let otherBody = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.sensor }),
            let ballNode = ballBody.node,
            let ballIndex = ballNode.userData?["ballIndex"] as? Int
        else { return }

        guard otherBody.node?.userData?["slotIndex"] as? Int == paths.first(where: { $0.ballIndex == ballIndex })?.slotIndex else {
            return
        }

        registerLanding(ballIndex: ballIndex, ballNode: ballNode)
    }

    func forceFinish() {
        finishIfNeeded()
    }

    deinit {
        safetyTimer?.invalidate()
    }

    // MARK: - Board Setup

    private func addBoundaryWalls() {
        let wallThickness: CGFloat = 20
        let leftWall = SKNode()
        leftWall.position = CGPoint(x: -wallThickness / 2, y: size.height / 2)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallThickness, height: size.height))
        configureStaticBody(leftWall.physicsBody!, category: PhysicsCategory.wall)
        addChild(leftWall)

        let rightWall = SKNode()
        rightWall.position = CGPoint(x: size.width + wallThickness / 2, y: size.height / 2)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: wallThickness, height: size.height))
        configureStaticBody(rightWall.physicsBody!, category: PhysicsCategory.wall)
        addChild(rightWall)

        let floor = SKNode()
        floor.position = CGPoint(x: size.width / 2, y: -wallThickness / 2)
        floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: wallThickness))
        configureStaticBody(floor.physicsBody!, category: PhysicsCategory.wall)
        addChild(floor)
    }

    private func addPegs(slotCount: Int) {
        for row in 0..<PlinkoEngine.rowCount {
            let pegsInRow = row + 2
            let y = rowHeight * CGFloat(row + 1)
            let offsetX = (size.width - pegSpacingX * CGFloat(pegsInRow - 1)) / 2

            for peg in 0..<pegsInRow {
                let x = offsetX + pegSpacingX * CGFloat(peg)
                let pegNode = SKShapeNode(circleOfRadius: 4)
                pegNode.fillColor = UIColor(red: 0.82, green: 0.62, blue: 0.10, alpha: 1)
                pegNode.strokeColor = .clear
                pegNode.position = CGPoint(x: x, y: y)
                pegNode.physicsBody = SKPhysicsBody(circleOfRadius: 4)
                configureStaticBody(pegNode.physicsBody!, category: PhysicsCategory.peg)
                pegNode.physicsBody?.restitution = 0.65
                pegNode.physicsBody?.friction = 0.1
                addChild(pegNode)
            }
        }
    }

    private func addSlots(slotCount: Int) {
        for (index, slot) in slots.enumerated() {
            let x = slotWidth * CGFloat(index) + slotWidth / 2

            let dividerLeft = SKNode()
            dividerLeft.position = CGPoint(x: slotWidth * CGFloat(index), y: slotY)
            dividerLeft.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 3, height: 36))
            configureStaticBody(dividerLeft.physicsBody!, category: PhysicsCategory.wall)
            addChild(dividerLeft)

            let sensor = SKNode()
            sensor.position = CGPoint(x: x, y: slotY)
            sensor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: slotWidth - 8, height: 28))
            sensor.physicsBody?.isDynamic = false
            sensor.physicsBody?.categoryBitMask = PhysicsCategory.sensor
            sensor.physicsBody?.contactTestBitMask = PhysicsCategory.ball
            sensor.physicsBody?.collisionBitMask = 0
            sensor.userData = NSMutableDictionary()
            sensor.userData?["slotIndex"] = index
            addChild(sensor)

            let slotBackground = SKShapeNode(rectOf: CGSize(width: slotWidth - 8, height: 28), cornerRadius: 8)
            slotBackground.fillColor = UIColor.white.withAlphaComponent(0.9)
            slotBackground.strokeColor = .clear
            slotBackground.position = CGPoint(x: x, y: slotY)
            slotBackground.zPosition = 20
            addChild(slotBackground)

            let label = SKLabelNode(text: slot.icon)
            label.fontSize = 14
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: x, y: slotY + 2)
            label.zPosition = 21
            addChild(label)
        }

        let rightDivider = SKNode()
        rightDivider.position = CGPoint(x: slotWidth * CGFloat(slotCount), y: slotY)
        rightDivider.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 3, height: 36))
        configureStaticBody(rightDivider.physicsBody!, category: PhysicsCategory.wall)
        addChild(rightDivider)
    }

    // MARK: - Balls

    private func scheduleBallSpawns() {
        for path in paths {
            let delay = Double(path.ballIndex) * 0.06
            let wait = SKAction.wait(forDuration: delay)
            let spawn = SKAction.run { [weak self] in
                self?.spawnBall(for: path)
            }
            run(SKAction.sequence([wait, spawn]))
        }
    }

    private func spawnBall(for path: PlinkoBallPath) {
        let slotCount = max(slots.count, PlinkoEngine.minSlots)
        let startColumn = path.columnPositions.first ?? slotCount / 2
        let startX = pegSpacingX * CGFloat(startColumn + 1)

        let radius: CGFloat = 7
        let ball = SKShapeNode(circleOfRadius: radius)
        if goldenBalls {
            ball.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 1)
            ball.strokeColor = UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1)
            ball.lineWidth = 1.5
        } else {
            ball.fillColor = UIColor(red: 0.95, green: 0.75, blue: 0.20, alpha: 1)
            ball.strokeColor = .clear
            ball.lineWidth = 0
        }
        ball.position = CGPoint(x: startX, y: size.height - 20)
        ball.zPosition = 10

        ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.sensor
        ball.physicsBody?.collisionBitMask = PhysicsCategory.peg | PhysicsCategory.wall
        ball.physicsBody?.restitution = 0.45
        ball.physicsBody?.friction = 0.05
        ball.physicsBody?.linearDamping = 0.05
        ball.physicsBody?.mass = 0.08

        ball.name = "ball_\(path.ballIndex)"
        ball.userData = NSMutableDictionary()
        ball.userData?["ballIndex"] = path.ballIndex

        if path.isJackpot {
            let ring = SKShapeNode(circleOfRadius: radius + 3)
            ring.fillColor = .clear
            ring.strokeColor = .orange
            ring.lineWidth = 2
            ring.zPosition = -1
            ball.addChild(ring)
        }

        if silverTrail {
            let emitTrail = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.05),
                    SKAction.run { [weak ball] in
                        guard let ball else { return }
                        let ghost = SKShapeNode(circleOfRadius: 5)
                        ghost.fillColor = UIColor.gray.withAlphaComponent(0.3)
                        ghost.strokeColor = .clear
                        ghost.position = ball.position
                        ghost.zPosition = 5
                        self.addChild(ghost)
                        ghost.run(SKAction.sequence([
                            SKAction.fadeOut(withDuration: 0.3),
                            SKAction.removeFromParent()
                        ]))
                    }
                ])
            )
            ball.run(emitTrail, withKey: "trail")
        }

        addChild(ball)
    }

    private func steerBalls() {
        enumerateChildNodes(withName: "ball_*") { [self] node, _ in
            guard
                let body = node.physicsBody,
                body.isDynamic,
                let ballIndex = node.userData?["ballIndex"] as? Int,
                let path = self.paths.first(where: { $0.ballIndex == ballIndex })
            else { return }

            let row = min(max(Int((self.size.height - node.position.y - 20) / self.rowHeight), 0), PlinkoEngine.rowCount - 1)
            let column = path.columnPositions[min(row, path.columnPositions.count - 1)]
            let targetX = self.pegSpacingX * CGFloat(column + 1)
            let deltaX = targetX - node.position.x

            let steerStrength: CGFloat = 0.015
            body.velocity.dx += deltaX * steerStrength

            if node.position.y < self.slotY + 40 {
                let slotX = self.slotWidth * CGFloat(path.slotIndex) + self.slotWidth / 2
                let finalDelta = slotX - node.position.x
                body.velocity.dx += finalDelta * 0.04
            }
        }
    }

    private func registerLanding(ballIndex: Int, ballNode: SKNode) {
        guard !landedBallIndices.contains(ballIndex) else { return }
        landedBallIndices.insert(ballIndex)

        ballNode.physicsBody?.isDynamic = false
        ballNode.run(SKAction.fadeAlpha(to: 0.6, duration: 0.2))

        onBallLanded?(ballIndex)

        if landedBallIndices.count >= paths.count {
            finishIfNeeded()
        }
    }

    private func finishIfNeeded() {
        guard !hasFinished else { return }
        hasFinished = true
        safetyTimer?.invalidate()
        safetyTimer = nil
        onAllBallsLanded?()
    }

    private func configureStaticBody(_ body: SKPhysicsBody, category: UInt32) {
        body.isDynamic = false
        body.categoryBitMask = category
        body.contactTestBitMask = category == PhysicsCategory.sensor ? PhysicsCategory.ball : 0
        body.collisionBitMask = PhysicsCategory.ball
    }
}
