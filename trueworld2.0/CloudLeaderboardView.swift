import SwiftUI
import SceneKit

struct CloudLeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var scene = SCNScene()
    
    let leaderboardData = [
        ("v-razor", 12500, AppDesignSystem.Colors.vibrantPink),
        ("neo_knight", 11200, .blue),
        ("trueworld_dev", 9800, .purple),
        ("aero_pilot", 8500, .cyan),
        ("ghost_racer", 7200, .orange)
    ]
    
    var body: some View {
        ZStack {
            SceneView(
                scene: scene,
                options: [.autoenablesDefaultLighting]
            )
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.4))
            
            VStack(spacing: 24) {
                // Header
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
                    VStack(alignment: .trailing) {
                        Text("GLOBAL RANKINGS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.blue)
                        Text("AI CLOUD LEADERBOARD")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // Leaderboard List
                VStack(spacing: 12) {
                    ForEach(0..<leaderboardData.count, id: \.self) { index in
                        let rank = leaderboardData[index]
                        HStack(spacing: 16) {
                            Text("\(index + 1)")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(rank.2)
                                .frame(width: 30)
                            
                            AppAvatar(url: nil, size: 40)
                                .overlay(Circle().stroke(rank.2.opacity(0.3), lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rank.0)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("GLOBAL SERVER #402")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            Spacer()
                            
                            Text("\(rank.1)")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(rank.2.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // My Rank Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR STANDING")
                            .font(.system(size: 10, weight: .black))
                        Text("Rank #1,242")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                    Text("TOP 15%")
                        .font(.system(size: 12, weight: .black))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppDesignSystem.Colors.vibrantPink)
                        .cornerRadius(20)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    func setupScene() {
        // Add a rotating 3D trophy or geometric feature background
        let trophy = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 2)
        trophy.firstMaterial?.diffuse.contents = Color.blue.opacity(0.1)
        trophy.firstMaterial?.emission.contents = Color.blue.opacity(0.2)
        let node = SCNNode(geometry: trophy)
        node.position = SCNVector3(0, 0, -20)
        scene.rootNode.addChildNode(node)
        
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.toValue = NSValue(scnVector4: SCNVector4(1, 1, 0, Float.pi * 2))
        rotation.duration = 20
        rotation.repeatCount = .infinity
        node.addAnimation(rotation, forKey: nil)
    }
}

#Preview {
    CloudLeaderboardView()
}
