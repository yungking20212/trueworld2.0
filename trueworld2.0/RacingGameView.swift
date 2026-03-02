import GameController
import SwiftUI
import SpriteKit
import Combine

class RacingScene: SKScene {
    var car: SKSpriteNode!
    
    // Physics properties
    var velocity: CGFloat = 0
    var angle: CGFloat = 0
    let acceleration: CGFloat = 0.2
    let friction: CGFloat = 0.98
    let maxSpeed: CGFloat = 8.0
    let turnSpeed: CGFloat = 0.05
    
    // Input state
    var isAccelerating = false
    var isBraking = false
    var turnDirection: CGFloat = 0 // -1 for left, 1 for right
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(white: 0.07, alpha: 1.0)
        setupCar()
        setupControllerSupport()
    }
    
    func setupCar() {
        car = SKSpriteNode(color: SKColor(AppDesignSystem.Colors.vibrantPink), size: CGSize(width: 40, height: 20))
        car.position = CGPoint(x: frame.midX, y: frame.midY)
        car.physicsBody = SKPhysicsBody(rectangleOf: car.size)
        car.physicsBody?.affectedByGravity = false
        car.shadowCastBitMask = 1
        addChild(car)
        
        // Add "Headlights"
        let light = SKLightNode()
        light.categoryBitMask = 1
        light.falloff = 1
        light.ambientColor = SKColor.white.withAlphaComponent(0.1)
        light.lightColor = SKColor.white
        light.position = CGPoint(x: 20, y: 0)
        car.addChild(light)
    }
    
    func setupControllerSupport() {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { _ in
            self.configureControllers()
        }
        configureControllers()
    }
    
    func configureControllers() {
        for controller in GCController.controllers() {
            controller.extendedGamepad?.valueChangedHandler = { [weak self] (gamepad, element) in
                guard let self = self else { return }
                
                if element == gamepad.buttonA {
                    self.isAccelerating = gamepad.buttonA.isPressed
                } else if element == gamepad.buttonB {
                    self.isBraking = gamepad.buttonB.isPressed
                } else if element == gamepad.leftThumbstick {
                    self.turnDirection = CGFloat(gamepad.leftThumbstick.xAxis.value)
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Physics update
        if isAccelerating {
            velocity += acceleration
        } else if isBraking {
            velocity -= acceleration * 1.5
        } else {
            velocity *= friction
        }
        
        // Limit speed
        velocity = max(min(velocity, maxSpeed), -maxSpeed / 2)
        
        // Steering
        if abs(velocity) > 0.1 {
            angle -= turnDirection * turnSpeed * (velocity / maxSpeed)
        }
        
        // Rotation and displacement
        car.zRotation = angle
        car.position.x += cos(angle) * velocity
        car.position.y += sin(angle) * velocity
        
        // Screen wrap (for prototype)
        if car.position.x > frame.maxX { car.position.x = frame.minX }
        if car.position.x < frame.minX { car.position.x = frame.maxX }
        if car.position.y > frame.maxY { car.position.y = frame.minY }
        if car.position.y < frame.minY { car.position.y = frame.maxY }
    }
}

struct RacingGameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentSpeed: Int = 0
    
    var scene: SKScene {
        let scene = RacingScene()
        scene.size = CGSize(width: 400, height: 852) // Standard iPhone 15 Pro height
        scene.scaleMode = .aspectFill
        return scene
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.top, 60)
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("VANTAGE RACING")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                        Text("BETA PROTO 1.0")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 65)
                    .padding(.trailing, 24)
                }
                
                Spacer()
                
                // HUD
                HStack(alignment: .bottom, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("SCORE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        Text("1,240")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: -5) {
                        Text("\(currentSpeed)")
                            .font(.system(size: 64, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: AppDesignSystem.Colors.vibrantPink.opacity(0.5), radius: 10)
                        
                        Text("KM/H")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
                .background(
                    AppDesignSystem.Colors.overlayBottomGradient
                        .frame(height: 150)
                )
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            // Simulate speed for display if we can't easily sync state back
            // In a real app we'd use a ViewModel or state sharing
        }
    }
}

#Preview {
    RacingGameView()
}
