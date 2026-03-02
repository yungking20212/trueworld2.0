import SwiftUI

struct AICloudGamingView: View {
    @StateObject private var creditManager = GameCreditManager.shared
    @StateObject private var registry = GameRegistry.shared
    @StateObject private var orchestrator = CloudOrchestrator.shared
    @StateObject private var neuralEngine = NeuralEngine.shared
    @StateObject private var streamingManager = CloudStreamingManager.shared
    @State private var selectedGame: UnifiedGame? = nil
    @State private var showingLeaderboard = false
    
    enum GameType: Identifiable {
        case racing3D, quantumArena, logicPulse
        var id: Self { self }
    }
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Premium Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TRUE WORLD STUDIOS")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                            HStack(spacing: 8) {
                                Text("AI GAMES ENGINE")
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("DEV")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        // Cloud Server Status
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Circle().fill(orchestrator.currentState == .streaming ? Color.green : Color.orange).frame(width: 6, height: 6)
                                Text(orchestrator.currentState.rawValue)
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(orchestrator.currentState == .streaming ? .green : .orange)
                            }
                            Text(orchestrator.region)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.trailing, 8)
                        Spacer()
                        
                        // Cloud Sync Status & Balance
                        // Cloud Telemetry (Next-Gen)
                        if orchestrator.currentState == .streaming {
                            HStack(spacing: 12) {
                                TelemetryBadge(label: "FPS", value: "\(orchestrator.fps)", color: .green)
                                TelemetryBadge(label: "BITRATE", value: String(format: "%.1f Mbps", orchestrator.bitrate), color: .blue)
                                TelemetryBadge(label: "LATENCY", value: "\(orchestrator.latency)ms", color: .green)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 8) {
                                // Server Latency
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 8))
                                    Text("24ms")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.green.opacity(0.8))
                                
                                if creditManager.isSyncing {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                                        .rotationEffect(.degrees(360))
                                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: creditManager.isSyncing)
                                } else {
                                    Image(systemName: "icloud.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.green)
                                }
                                Text(creditManager.isSyncing ? "SYNCING..." : "CLOUD SYNCED")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(creditManager.isSyncing ? AppDesignSystem.Colors.vibrantBlue : .green)
                            }
                            
                            Text("\(creditManager.balance)")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Text(creditManager.userTier.rawValue)
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(creditManager.userTier == .premium ? .yellow : .white.opacity(0.6))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(creditManager.userTier == .premium ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Text("CREDITS")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(creditManager.isSyncing ? AppDesignSystem.Colors.vibrantBlue.opacity(0.3) : AppDesignSystem.Colors.vibrantPink.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Session Dashboard (The 5 Pillars)
                    if orchestrator.currentState != .idle {
                        VStack(spacing: 0) {
                            if orchestrator.currentState == .streaming {
                                ZStack {
                                    if let track = streamingManager.remoteVideoTrack {
                                        RTCVideoView(videoTrack: track)
                                            .frame(height: 180)
                                            .cornerRadius(24)
                                    } else {
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(Color.black.opacity(0.8))
                                            .frame(height: 180)
                                            .overlay(
                                                VStack(spacing: 12) {
                                                    ProgressView()
                                                        .accentColor(.blue)
                                                    Text("INITIALIZING NEURAL CORE...")
                                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                                        .foregroundColor(.blue)
                                                }
                                            )
                                    }
                                    
                                    // Live Indicator
                                    VStack {
                                        HStack {
                                            HStack(spacing: 4) {
                                                Circle().fill(Color.red).frame(width: 4, height: 4)
                                                Text("LIVE PREVIEW")
                                                    .font(.system(size: 8, weight: .black))
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.5))
                                            .cornerRadius(6)
                                            .padding(12)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .padding(.bottom, 16)
                            }
                            
                            // Engine Diagnostics Panel
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("ENGINE DIAGNOSTICS")
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Text("STABLE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                
                                HStack(spacing: 20) {
                                    DiagnosticMetric(label: "NEURAL LOAD", value: "42%", color: .cyan)
                                    DiagnosticMetric(label: "PHYS_BUFFER", value: "1.2ms", color: .purple)
                                    DiagnosticMetric(label: "AI_OPS", value: "12.4k/s", color: .orange)
                                }
                                
                                // Developer Controls
                                HStack {
                                    EngineControlButton(label: "FLUSH CACHE")
                                    EngineControlButton(label: "REBOOT CORE")
                                    EngineControlButton(label: "MOD_LOADER")
                                }
                                .padding(.top, 4)
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            
                            SessionDashboard(orchestrator: orchestrator, neuralEngine: neuralEngine)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Main Features: True World Originals
                    VStack(alignment: .leading, spacing: 20) {
                        Text("TRUE WORLD ORIGINALS")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal)
                        
                        ForEach(registry.games.filter { $0.category == .original }) { game in
                            GameHeroCard(
                                title: game.title,
                                subtitle: game.subtitle,
                                description: game.description,
                                imageName: game.iconName,
                                color: game.color
                            ) {
                                selectedGame = game
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // True World Cloud Partner Program (Marketplace Pillar)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TRUE WORLD ENGINE PARTNER PROGRAM")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                                Text("Join the AI Games Engine Marketplace")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "plus.square.fill.on.square.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 24))
                        }
                        
                        Text("Are you an Unreal or Unity developer? Bring your game to the True World Cloud for free hosting, 70/30 revenue split, and AI-powered NPC behaviors.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 12) {
                            PartnerBenefitBadge(icon: "bolt.horizontal.fill", text: "FREE BETA HOSTING")
                            PartnerBenefitBadge(icon: "dollarsign.circle.fill", text: "70/30 SPLIT")
                            PartnerBenefitBadge(icon: "brain.head.profile", text: "AI NPC FEATURES")
                        }
                        
                        // Developer Revenue Split Visualizer
                        HStack {
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 10)
                                Capsule()
                                    .fill(Color.yellow)
                                    .frame(width: 140, height: 10) // 70% width
                            }
                            
                            Text("70%")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.yellow)
                        }
                        .padding(.top, 4)
                        
                        Button(action: {
                            // Placeholder for opening developer portal
                        }) {
                            HStack {
                                Text("APPLY TO PARTNER PROGRAM")
                                    .font(.system(size: 12, weight: .black))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .foregroundColor(.black)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(LinearGradient(colors: [Color.yellow.opacity(0.1), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(32)
                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                    
                    // Credit Economy Overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CLOUD ECONOMY")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 20) {
                            EconomyStat(label: "COST", value: "10 RC / min", sublabel: "Performance Tier")
                            EconomyStat(label: "HOURLY", value: "600 RC", sublabel: "Avg. Session")
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    creditManager.userTier = creditManager.userTier == .standard ? .premium : .standard
                                }
                            }) {
                                Text(creditManager.userTier == .premium ? "PREMIUM ACTIVE" : "UPGRADE TO PREMIUM")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(creditManager.userTier == .premium ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(creditManager.userTier == .premium ? Color.yellow : AppDesignSystem.Colors.vibrantBlue)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if creditManager.userTier == .premium {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                                Text("PRIORITY GPU QUEUE ENABLED")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.yellow.opacity(0.8))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Engine Marketplace (Unreal/Unity)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("ENGINE MARKETPLACE (UNREAL/UNITY)")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.yellow.opacity(0.6))
                            Spacer()
                            Text("ALL PARTNERS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(registry.games.filter { $0.category == .partner }) { game in
                                    GameCompactCard(
                                        title: game.title,
                                        category: game.subtitle,
                                        icon: game.iconName,
                                        color: game.color
                                    ) {
                                        selectedGame = game
                                    }
                                    .frame(width: 220)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Developer Showcase Shelf
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("COMMUNITY ARCADE")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("SEE ALL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(registry.games.filter { $0.category == .developer }) { game in
                                    GameCompactCard(
                                        title: game.title,
                                        category: game.subtitle,
                                        icon: game.iconName,
                                        color: game.color
                                    ) {
                                        selectedGame = game
                                    }
                                    .frame(width: 200)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Live Tournament Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LIVE TOURNAMENT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                            Text("World Championship Qualifiers")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(20)
                    .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Neural Logic Console
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .foregroundColor(.cyan)
                            Text("NEURAL_LOGIC_CONSOLE")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("[04:20:11] AI_CORE_INIT: SUCCESS")
                            Text("[04:20:12] NEURAL_SYNC_CONNECTED")
                            Text("[04:20:14] LOADING_PHYSICS_PREDICTOR...")
                            Text("[04:20:15] BEHAVIOR_TREE_INJECTED: 'CYBER_COMBAT_V5'")
                                .foregroundColor(.green)
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 120)
                }
            }
        }
        .fullScreenCover(isPresented: $showingLeaderboard) {
            CloudLeaderboardView()
        }
        .fullScreenCover(item: $selectedGame) { game in
            if game.is3D {
                if game.title.contains("RACING") {
                    VantageRacing3DView()
                } else if game.title.contains("LOGIC") {
                    LogicPulseCombatView()
                } else if game.title.contains("VOID PROTOCOL") {
                    VoidProtocolView()
                } else {
                    QuantumArenaView()
                }
            } else {
                DeveloperGameView(game: game)
            }
        }
    }
}

struct PartnerBenefitBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 8, weight: .black))
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(6)
    }
}

struct EconomyStat: View {
    let label: String
    let value: String
    let sublabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white.opacity(0.3))
            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text(sublabel)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct GameHeroCard: View {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(color.opacity(0.15))
                        .frame(height: 220)
                    
                    Image(systemName: imageName)
                        .font(.system(size: 100))
                        .foregroundColor(color.opacity(0.5))
                        .shadow(color: color, radius: 20)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                HStack {
                    Text("LAUNCH ENGINE")
                        .font(.system(size: 12, weight: .black))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(color)
                .cornerRadius(14)
            }
            .padding(24)
            .glassy(cornerRadius: 32)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GameCompactCard: View {
    let title: String
    let category: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(title)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .glassy(cornerRadius: 24)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SessionDashboard: View {
    @ObservedObject var orchestrator: CloudOrchestrator
    @ObservedObject var neuralEngine: NeuralEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LIVE SESSION BRAIN")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                Spacer()
                Image(systemName: "cpu.fill")
                    .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
            }
            
            HStack(spacing: 20) {
                // GPU Pillar
                VStack(alignment: .leading, spacing: 4) {
                    Text("P1: CLOUD GPU")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Text(orchestrator.activeGPUType)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Neural Pillar
                VStack(alignment: .trailing, spacing: 4) {
                    Text("P5: AI LAYER")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Text(neuralEngine.lastAIAction)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // Usage Metering (P3 & P4)
            VStack(alignment: .leading, spacing: 10) {
                Text("P3 & P4: USAGE METERING & BALANCING")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                HStack(spacing: 12) {
                    TelemetryBadge(label: "SESSION TIME", value: formatDuration(orchestrator.sessionDuration), color: .white)
                    TelemetryBadge(label: "CREDITS BURNED", value: "\(orchestrator.creditsBurned) RC", color: .orange)
                    TelemetryBadge(label: "RATE", value: "10 RC/min", color: .blue)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppDesignSystem.Colors.vibrantBlue.opacity(0.2), lineWidth: 1))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct GameSmallCard: View {
    let title: String
    let icon: String
    let reward: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "banknote")
                    Text(reward)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassy(cornerRadius: 20)
    }
}

struct TelemetryBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }
}

struct DiagnosticMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct EngineControlButton: View {
    let label: String
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            Text(label)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.2), lineWidth: 1))
        }
    }
}

#Preview {
    AICloudGamingView()
}
