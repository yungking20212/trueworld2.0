import SwiftUI
import Combine

enum GameCategory: String, Codable, CaseIterable {
    case original = "True World Originals"
    case developer = "Developer Arcade"
    case partner = "Cloud Partner Program"
    case classic = "Classic Beta"
}

struct UnifiedGame: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let description: String
    let iconName: String
    let category: GameCategory
    let colorHex: String
    let rewardAmount: Int
    let is3D: Bool
    
    var color: Color {
        Color(hex: colorHex)
    }
}

class GameRegistry: ObservableObject {
    static let shared = GameRegistry()
    
    @Published var games: [UnifiedGame] = []
    
    private init() {
        setupStaticRegistry()
    }
    
    private func setupStaticRegistry() {
        self.games = [
            UnifiedGame(
                id: UUID(),
                title: "VANTAGE RACING 3D",
                subtitle: "CLOUD STREAMED • NEURAL PHYSICS",
                description: "Next-gen 3D racing streamed via True World AI Cloud.",
                iconName: "car.side.fill",
                category: .original,
                colorHex: "FF0080",
                rewardAmount: 10,
                is3D: true
            ),
            UnifiedGame(
                id: UUID(),
                title: "LOGIC PULSE",
                subtitle: "AI CLOUD COMBAT ENGINE",
                description: "Massive-scale 1v1 combat powered by True World Cloud Servers.",
                iconName: "brain.head.profile",
                category: .original,
                colorHex: "00F2FF",
                rewardAmount: 50,
                is3D: true
            ),
            UnifiedGame(
                id: UUID(),
                title: "VOID PROTOCOL",
                subtitle: "CLOUD STREAMED • NEURAL TPS",
                description: "Deep Cyberpunk 3D TPS. Tech-enhanced combat in a dark neon dystopia.",
                iconName: "target",
                category: .original,
                colorHex: "00FFFF",
                rewardAmount: 100,
                is3D: true
            ),
            UnifiedGame(
                id: UUID(),
                title: "NEON STRIKE",
                subtitle: "DEV: CYBER_CORE",
                description: "Fast-paced arcade shooter from the community.",
                iconName: "bolt.fill",
                category: .developer,
                colorHex: "AA00FF",
                rewardAmount: 25,
                is3D: false
            ),
            UnifiedGame(
                id: UUID(),
                title: "PIXEL QUEST",
                subtitle: "DEV: RETRO_KID",
                description: "A classic platformer reinvented for AI Cloud Gaming.",
                iconName: "gamecontroller.fill",
                category: .developer,
                colorHex: "FFD600",
                rewardAmount: 15,
                is3D: false
            ),
            UnifiedGame(
                id: UUID(),
                title: "CYBERPUNK ARENA",
                subtitle: "PARTNER: UNREAL ENGINE 5",
                description: "A high-fidelity partner game running on NVIDIA A100 Cloud GPU.",
                iconName: "square.grid.3x3.topleft.filled",
                category: .partner,
                colorHex: "00FF00",
                rewardAmount: 100,
                is3D: true
            ),
            UnifiedGame(
                id: UUID(),
                title: "VOID RUNNER",
                subtitle: "PARTNER: UNITY AA STUDIO",
                description: "Ultra-fast partner racing engine with 120fps WebRTC streaming.",
                iconName: "airplane.circle.fill",
                category: .partner,
                colorHex: "FFFFFF",
                rewardAmount: 80,
                is3D: true
            )
        ]
    }
}
