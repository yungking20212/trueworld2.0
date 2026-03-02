import SwiftUI

struct CommunityGuidelinesView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    Text("Core Protocols")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COMMUNITY GUIDELINES")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                                .tracking(2)
                            
                            Text("The Neural Integrity Protocol")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        Text("Trueworld 2.0 is an immersive planetary network. To preserve the high-fidelity experience of all users, the following guidelines are non-negotiable.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                        
                        // Guideline Sections
                        GuidelineItem(
                            number: "01",
                            title: "AUTHENTIC BROADCASTS",
                            description: "Visual transmissions must represent genuine geospatial events. Manipulation of location data to deceive the planetary map is a violation of territory integrity."
                        )
                        
                        GuidelineItem(
                            number: "02",
                            title: "TERRITORY ETIQUETTE",
                            description: "The 'Own Your Block' feature is a competitive digital landscape. Harassment or coordinated suppression of other creators' visual footprints is prohibited."
                        )
                        
                        GuidelineItem(
                            number: "03",
                            numColor: .pink,
                            title: "NEURAL WELL-BEING",
                            description: "Content that promotes violence, exploitation, or the degradation of the collective human experience will be purged from the neural net instantly."
                        )
                        
                        GuidelineItem(
                            number: "04",
                            title: "VANTAGE INTEGRITY",
                            description: "Artificial inflation of likes, views, or neural scores through bot protocols will result in permanent exclusion from the monetization engine."
                        )
                        
                        VStack(spacing: 12) {
                            Text("TERMINATION OF PRESENCE")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Text("Violating these protocols may lead to the immediate severance of your identity from the Trueworld network and forfeiture of all accumulated neural revenue.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 40)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct GuidelineItem: View {
    let number: String
    var numColor: Color = .cyan
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Text(number)
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .foregroundColor(numColor.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(2)
                }
            }
        }
    }
}

#Preview {
    CommunityGuidelinesView()
}
