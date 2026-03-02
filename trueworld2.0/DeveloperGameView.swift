import SwiftUI

struct DeveloperGameView: View {
    let game: UnifiedGame
    @Environment(\.dismiss) var dismiss
    @StateObject private var creditManager = GameCreditManager.shared
    @StateObject private var orchestrator = CloudOrchestrator.shared
    @StateObject private var neuralEngine = NeuralEngine.shared
    @State private var loadingProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(game.category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(game.color)
                        Text(game.title)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Game Placeholder / Loader
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: loadingProgress)
                            .stroke(game.color, lineWidth: 4)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: game.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(game.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text(orchestrator.currentState.rawValue)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(neuralEngine.lastAIAction)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(game.color.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Reward Banner
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("PLAY TO EARN UP TO \(game.rewardAmount) CREDITS")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(game.color.opacity(0.2))
                .cornerRadius(20)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            orchestrator.launchSession(for: game.id)
            
            withAnimation(.linear(duration: 5.0)) {
                loadingProgress = 1.0
            }
            
            // Peak at Neural Engine
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                neuralEngine.generateBehavior(for: game.title)
            }
        }
        .onDisappear {
            orchestrator.terminateSession()
        }
    }
}
