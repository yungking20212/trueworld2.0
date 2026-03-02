import SwiftUI
import SceneKit

struct LogicPulseCombatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var creditManager = GameCreditManager.shared
    @StateObject private var orchestrator = CloudOrchestrator.shared
    @StateObject private var neuralEngine = NeuralEngine.shared
    @State private var scene = SCNScene()
    @State private var playerHP: CGFloat = 1.0
    @State private var enemyHP: CGFloat = 1.0
    @State private var gameStatus: String = "CONNECTING..."
    
    var body: some View {
        ZStack {
            SceneView(
                scene: scene,
                pointOfView: nil,
                options: [.autoenablesDefaultLighting]
            )
            .ignoresSafeArea()
            
            // Interaction Layer
            HStack {
                // Character Control Areas
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .onTapGesture { attack(isPlayer: true) }
                
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .onTapGesture { attack(isPlayer: true) }
            }
            .ignoresSafeArea()
            
            // HUD Overlay
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PLAYER_SYNC")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.blue)
                        HPBar(label: "LOGIC_LINK", progress: playerHP, color: .blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 10) {
                        Text("AI_CORE_V3")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                        HPBar(label: "CORE_STABILITY", progress: enemyHP, color: .red)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 60)
                
                Spacer()
                
                if !gameStatus.isEmpty {
                    Text(gameStatus)
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.bottom, 100)
                }
                
                Button(action: { dismiss() }) {
                    Text("EXIT SIMULATION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            orchestrator.launchSession(for: UUID()) // Simulated ID
            setupArena()
        }
        .onDisappear {
            orchestrator.terminateSession()
        }
    }
    
    func setupArena() {
        // Metallic Floor
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = Color.black
        floor.firstMaterial?.specular.contents = Color.white.opacity(0.5)
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
        
        // Player (Blue Sphere)
        let player = SCNSphere(radius: 1)
        player.firstMaterial?.diffuse.contents = Color.blue
        player.firstMaterial?.emission.contents = Color.blue.opacity(0.3)
        let playerNode = SCNNode(geometry: player)
        playerNode.position = SCNVector3(-4, 1, 0)
        playerNode.name = "player"
        scene.rootNode.addChildNode(playerNode)
        
        // Enemy (Red Sphere)
        let enemy = SCNSphere(radius: 1)
        enemy.firstMaterial?.diffuse.contents = Color.red
        enemy.firstMaterial?.emission.contents = Color.red.opacity(0.3)
        let enemyNode = SCNNode(geometry: enemy)
        enemyNode.position = SCNVector3(4, 1, 0)
        enemyNode.name = "enemy"
        scene.rootNode.addChildNode(enemyNode)
        
        // Dynamic Lighting
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1500
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 10, 5)
        scene.rootNode.addChildNode(lightNode)
        
        // Neural Link Overlay Simulation
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            neuralEngine.updatePhysicsPrediction()
        }
        
        // AI Logic Loop
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            if enemyHP > 0 && playerHP > 0 {
                attack(isPlayer: false)
            }
        }
    }
    
    func attack(isPlayer: Bool) {
        if isPlayer {
            withAnimation {
                enemyHP -= 0.1
                if enemyHP <= 0 {
                    enemyHP = 0
                    gameStatus = "VICTORY"
                    creditManager.addCredits(50)
                }
            }
        } else {
            withAnimation {
                playerHP -= 0.05
                if playerHP <= 0 {
                    playerHP = 0
                    gameStatus = "SYNC FAILED"
                }
            }
        }
    }
}
