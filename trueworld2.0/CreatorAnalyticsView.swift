import SwiftUI
import Charts

struct CreatorAnalyticsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Simulated data for 20x multiplier effect
    let standardData: [RevenuePoint] = [
        .init(day: "MON", cents: 120),
        .init(day: "TUE", cents: 150),
        .init(day: "WED", cents: 110),
        .init(day: "THU", cents: 200),
        .init(day: "FRI", cents: 180),
        .init(day: "SAT", cents: 250),
        .init(day: "SUN", cents: 300)
    ]
    
    var aiStoryData: [RevenuePoint] {
        standardData.map { .init(day: $0.day, cents: $0.cents * 20) }
    }
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("NEURAL ANALYTICS")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Summary Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("REVENUE MULTIPLIER ACTIVE")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.purple)
                            
                            HStack(alignment: .bottom, spacing: 12) {
                                Text("20X")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("BOOST RATE")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.bottom, 12)
                            }
                            
                            Text("Your stories are currently optimized with neural ad-placement, yielding the maximum possible CPM in the Trueworld ecosystem.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        // Chart Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("WEEKLY PERFORMANCE COMPARISON")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Chart {
                                ForEach(standardData) { point in
                                    LineMark(
                                        x: .value("Day", point.day),
                                        y: .value("Revenue", Double(point.cents) / 100.0)
                                    )
                                    .foregroundStyle(.blue.opacity(0.3))
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                }
                                
                                ForEach(aiStoryData) { point in
                                    AreaMark(
                                        x: .value("Day", point.day),
                                        y: .value("Revenue", Double(point.cents) / 100.0)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.4), .blue.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    
                                    LineMark(
                                        x: .value("Day", point.day),
                                        y: .value("Revenue", Double(point.cents) / 100.0)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan, .purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(StrokeStyle(lineWidth: 4))
                                }
                            }
                            .frame(height: 250)
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                        .foregroundStyle(Color.white.opacity(0.1))
                                    AxisValueLabel {
                                        if let amount = value.as(Double.self) {
                                            Text("$\(Int(amount))")
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let day = value.as(String.self) {
                                            Text(day)
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                }
                            }
                            
                            HStack(spacing: 20) {
                                LegendItem(color: .blue.opacity(0.3), label: "STANDARD VIDS", isDashed: true)
                                LegendItem(color: .purple, label: "AI STORY 20X", isDashed: false)
                            }
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        // Insight Card
                        InsightItem(
                            icon: "bolt.shield.fill",
                            title: "NEURAL OPTIMIZATION READY",
                            description: "Your next story is projected to earn 18.4x more than your average video performance based on current engagement spikes."
                        )
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct RevenuePoint: Identifiable {
    let id = UUID()
    let day: String
    let cents: Int
}

struct LegendItem: View {
    let color: Color
    let label: String
    let isDashed: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Group {
                if isDashed {
                    Rectangle()
                        .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .frame(width: 20, height: 2)
                } else {
                    Capsule()
                        .fill(color)
                        .frame(width: 20, height: 4)
                }
            }
            Text(label)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct InsightItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
