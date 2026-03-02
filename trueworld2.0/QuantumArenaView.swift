import SwiftUI
import SceneKit

struct QuantumArenaView: View {
    @Environment(\.dismiss) var dismiss
    @State private var scene = SCNScene()
    
    var body: some View {
        ZStack {
            SceneView(
                scene: scene,
                pointOfView: nil,
                options: [.autoenablesDefaultLighting]
            )
            .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("QUANTUM ARENA")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.blue)
                        Text("PRE-ALPHA BUILD")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Combat HUD
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        HPBar(label: "NEURAL LINK", progress: 0.8, color: .blue)
                        HPBar(label: "QUANTUM SHIELD", progress: 0.4, color: .cyan)
                    }
                    Spacer()
                }
                .padding(30)
                .background(AppDesignSystem.Colors.overlayBottomGradient)
            }
        }
        .onAppear {
            setupArena()
        }
    }
    
    func setupArena() {
        // Neon Grid Floor
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = Color.black
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
        
        // Central Pulse Core
        let core = SCNSphere(radius: 2)
        core.firstMaterial?.diffuse.contents = Color.blue.opacity(0.1)
        core.firstMaterial?.emission.contents = Color.blue
        let coreNode = SCNNode(geometry: core)
        coreNode.position = SCNVector3(0, 2, 0)
        scene.rootNode.addChildNode(coreNode)
        
        // Add some floating geometric shapes
        for _ in 0..<20 {
            let poly = SCNPyramid(width: 1, height: 1, length: 1)
            poly.firstMaterial?.diffuse.contents = Color.white.opacity(0.2)
            let node = SCNNode(geometry: poly)
            node.position = SCNVector3(Float.random(in: -20...20), Float.random(in: 2...10), Float.random(in: -20...20))
            scene.rootNode.addChildNode(node)
        }
    }
}

struct HPBar: View {
    let label: String
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white.opacity(0.6))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.1))
                    .frame(width: 120, height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 120 * progress, height: 4)
                    .shadow(color: color, radius: 4)
            }
        }
    }
}

#Preview {
    QuantumArenaView()
}
