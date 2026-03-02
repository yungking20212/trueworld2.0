import SwiftUI
import Combine

class NeuralEngine: ObservableObject {
    static let shared = NeuralEngine()
    
    @Published var lastAIAction: String = "Monitoring neural link..."
    @Published var difficultyModifier: Double = 1.0
    
    func generateBehavior(for entity: String) {
        let behaviors = [
            "Calculating aggressive flanking route...",
            "Adjusting recoil pattern for neural prediction...",
            "Predicting user movement at 60fps...",
            "Modulating voice-NPC tone to 'Defensive'...",
            "Applying neural physics smoothing..."
        ]
        
        lastAIAction = behaviors.randomElement() ?? "Neural link stable."
    }
    
    func updatePhysicsPrediction() {
        lastAIAction = "Predicting next 3 frames via Neural Physics..."
    }
}
