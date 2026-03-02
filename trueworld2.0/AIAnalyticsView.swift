import SwiftUI

struct AIAnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("NEURAL ANALYTICS")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                        Spacer()
                        Image(systemName: "sparkles")
                            .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Main Chart Area
                    VStack(alignment: .leading, spacing: 15) {
                        Text("WORLD PULSE TREND")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        
                        NeuralTrendChart()
                            .frame(height: 200)
                    }
                    .padding(20)
                    .glassy(cornerRadius: 24)
                    .padding(.horizontal)
                    
                    // Prediction Cards
                    VStack(alignment: .leading, spacing: 20) {
                        Text("AI PREDICTIONS")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal)
                        
                        PredictionCard(title: "Tokyo Viral Alert", content: "Growth expected in Shibuya +140%", probability: 0.92)
                        PredictionCard(title: "Music Meta Shift", content: "Hyper-pop variants trending in NYC", probability: 0.78)
                    }
                    
                    // Neural Log Stream
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SYSTEM LOGS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("[SYSTEM] Scanning geo-nodes...")
                            Text("[NEURAL] Pattern recognized: 'Cyberpunk'")
                            Text("[DATA] Syncing nodes with Eye World...")
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct NeuralTrendChart: View {
    @State private var animate = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<12) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppDesignSystem.Colors.primaryGradient)
                    .frame(width: 14, height: animate ? CGFloat.random(in: 40...180) : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(Double(i) * 0.05), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct PredictionCard: View {
    let title: String
    let content: String
    let probability: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(probability * 100))%")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            // Prob bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                Capsule()
                    .fill(AppDesignSystem.Colors.vibrantBlue)
                    .frame(width: 200 * probability, height: 4)
            }
        }
        .padding(20)
        .glassy(cornerRadius: 20)
        .padding(.horizontal)
    }
}
