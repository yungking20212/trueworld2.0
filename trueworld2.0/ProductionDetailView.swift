import SwiftUI

struct ProductionDetailView: View {
    let production: AIProduction
    @StateObject private var service = ProductionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedScene: AIScene? = nil
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack {
                        Text(production.title.uppercased())
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text(production.genre)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        // Project Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NEURAL SCRIPT PROMPT")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text(production.scriptPrompt)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(20)
                                .glassy(cornerRadius: 16)
                        }
                        .padding(.horizontal)
                        
                        // Scenes List
                        VStack(alignment: .leading, spacing: 20) {
                            Text("CINEMATIC SCENES")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.horizontal)
                            
                            ForEach(production.scenes) { scene in
                                SceneRow(scene: scene, productionId: production.id)
                                    .onTapGesture {
                                        if scene.status == .completed {
                                            selectedScene = scene
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .fullScreenCover(item: $selectedScene) { scene in
            ScenePlayerView(scene: scene)
        }
    }
}

struct SceneRow: View {
    let scene: AIScene
    let productionId: UUID
    @StateObject private var service = ProductionService.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon / Preview Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                if scene.status == .completed {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                } else if scene.status == .generating {
                    ProgressView().tint(AppDesignSystem.Colors.vibrantBlue)
                } else {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(scene.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(scene.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                
                HStack {
                    StatusBadge(status: scene.status)
                    Spacer()
                    if scene.status == .pending {
                        Button("GENERATE VIDEO") {
                            Task {
                                await service.triggerVideoGeneration(for: scene.id, in: productionId)
                            }
                        }
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                    }
                }
            }
        }
        .padding(16)
        .glassy(cornerRadius: 20)
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let status: AIScene.GenerationStatus
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 8, weight: .black, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(4)
    }
    
    var backgroundColor: Color {
        switch status {
        case .completed: return .green
        case .generating: return AppDesignSystem.Colors.vibrantBlue
        case .pending: return .orange
        case .failed: return .red
        }
    }
}

struct ScenePlayerView: View {
    let scene: AIScene
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                Text("NEURAL VIDEO PLAYBACK")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                
                if let url = scene.videoURL {
                    // Use actual video player here
                    Text("Playing: \(url.lastPathComponent)")
                        .foregroundColor(.white)
                } else {
                    Text("Video path not found in simulation")
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
            }
        }
    }
}
