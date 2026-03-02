import SwiftUI
import SceneKit

struct VoidProtocolView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var orchestrator = CloudOrchestrator.shared
    @StateObject private var neuralEngine = NeuralEngine.shared
    @StateObject private var creditManager = GameCreditManager.shared
    
    // Scene State
    @State private var scene = SCNScene()
    @State private var playerNode: SCNNode?
    @State private var cameraNode: SCNNode?
    
    // Controls
    @State private var moveVector = CGPoint.zero
    @State private var isFiring = false
    
    var body: some View {
        ZStack {
            // 3D Engine Layer
            SceneView(
                scene: scene,
                pointOfView: cameraNode,
                options: [.autoenablesDefaultLighting, .rendersContinuously]
            )
            .ignoresSafeArea()
            
            // HUD Layer
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VOID PROTOCOL")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                        Text("NEURAL_LINK: STABLE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("CREDITS")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(creditManager.balance)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Bottom Controls & Status
                HStack(alignment: .bottom) {
                    // Virtual Joystick (Left)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 100, height: 100)
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .offset(x: moveVector.x * 30, y: moveVector.y * 30)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let limit: CGFloat = 40
                                let x = max(min(value.translation.width, limit), -limit) / limit
                                let y = max(min(value.translation.height, limit), -limit) / limit
                                moveVector = CGPoint(x: x, y: y)
                            }
                            .onEnded { _ in
                                moveVector = .zero
                            }
                    )
                    
                    Spacer()
                    
                    // Combat Actions (Right)
                    VStack(spacing: 20) {
                        // Special Power (Telekinesis)
                        Button(action: { triggerPower() }) {
                            Image(systemName: "bolt.horizontal.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.cyan)
                                .background(Circle().fill(.cyan.opacity(0.2)).blur(radius: 10))
                        }
                        
                        // Fire Button
                        Button(action: { isFiring = true }) {
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .red.opacity(0.5), radius: 20)
                        }
                        .pressEvents(onPress: { isFiring = true }, onRelease: { isFiring = false })
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
            
            // Initialization Overlay
            if orchestrator.currentState != .streaming {
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 20) {
                            ProgressView()
                                .tint(.blue)
                            Text(orchestrator.currentState.rawValue)
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                    )
            }
        }
        .onAppear {
            orchestrator.launchSession(for: UUID())
            setupWorld()
        }
        .onDisappear {
            orchestrator.terminateSession()
        }
    }
    
    func setupWorld() {
        // Dark Cyberpunk Environment
        scene.background.contents = UIColor.black
        
        // Floor (Metal Grid)
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.05, alpha: 1.0)
        floor.firstMaterial?.specular.contents = UIColor.white
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
        
        // Player (Cyber-Cyborg placeholder)
        let playerBody = SCNBox(width: 1, height: 2, length: 1, chamferRadius: 0.2)
        playerBody.firstMaterial?.diffuse.contents = UIColor.darkGray
        playerBody.firstMaterial?.emission.contents = UIColor.blue.withAlphaComponent(0.3)
        playerNode = SCNNode(geometry: playerBody)
        playerNode?.position = SCNVector3(0, 1, 0)
        scene.rootNode.addChildNode(playerNode!)
        
        // Camera setup (TPS)
        cameraNode = SCNNode()
        cameraNode?.camera = SCNCamera()
        cameraNode?.position = SCNVector3(0, 5, 8)
        cameraNode?.eulerAngles = SCNVector3(-0.4, 0, 0)
        playerNode?.addChildNode(cameraNode!)
        
        // Distant Neon Towers
        for _ in 0..<10 {
            let tower = SCNBox(width: 10, height: 100, length: 10, chamferRadius: 0)
            tower.firstMaterial?.diffuse.contents = UIColor(white: 0.1, alpha: 1.0)
            tower.firstMaterial?.emission.contents = [UIColor.blue, UIColor.magenta, UIColor.cyan].randomElement()?.withAlphaComponent(0.2)
            let towerNode = SCNNode(geometry: tower)
            towerNode.position = SCNVector3(Float.random(in: -100...100), 50, Float.random(in: -100...0))
            scene.rootNode.addChildNode(towerNode)
        }
        
        // Physics Loop
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updatePhysics()
        }
    }
    
    func updatePhysics() {
        guard let player = playerNode else { return }
        
        // Move based on joystick
        let speed: Float = 0.15
        player.position.x += Float(moveVector.x) * speed
        player.position.z += Float(moveVector.y) * speed
        
        // Neural Prediction simulation
        if isFiring {
            neuralEngine.updatePhysicsPrediction()
        }
    }
    
    func triggerPower() {
        neuralEngine.generateBehavior(for: "Cyber_Ability_Telekinesis")
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

// Helper for fire button press events
extension View {
    func pressEvents(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in onPress() })
                .onEnded({ _ in onRelease() })
        )
    }
}
