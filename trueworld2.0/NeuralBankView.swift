import SwiftUI
import Supabase
import Stripe

struct NeuralBankView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var eyeViewModel = EyeWorldViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Strategic Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("NEURAL_STRATEGIC_HQ")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text("UNIT_ID: \(viewModel.userProfile?.username?.uppercased() ?? "ALPHA_USER")")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 16))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Neural Revenue & Momentum Dashboard
                        HStack(spacing: 12) {
                            // Primary Revenue
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TOTAL_EARNINGS")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Text("$\(Double(viewModel.userProfile?.revenueCents ?? 0) / 100.0, specifier: "%.2f")")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("AD_POOL_SHARE: \(viewModel.userProfile?.monetizationEnabled == true ? "0.04%" : "0.00%")")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            
                            // MOMENTUM SCORE
                            VStack(alignment: .leading, spacing: 8) {
                                Text("MOMENTUM_STRENGTH")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Text(String(format: "%.1f", viewModel.userProfile?.momentumScore ?? 0.0))
                                    .font(.system(size: 32, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 8))
                                    Text("\(viewModel.userProfile?.momentumScore ?? 0.0 > 0 ? "+0.0% LIVE" : "STABLE")")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // DOMINION STATUS (v3 Territorial Influence)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TERRITORIAL_INFLUENCE")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("OWN_YOUR_BLOCK")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cyan.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            HStack(spacing: 12) {
                                DominionStat(label: "CITY_RANK", value: viewModel.userProfile?.cityName != nil ? "#\(viewModel.userProfile?.dailyRank ?? 0) \(viewModel.userProfile?.cityName?.uppercased() ?? "")" : "UNRANKED", color: .cyan)
                                DominionStat(label: "GLOBAL_RANK", value: "#\(viewModel.userProfile?.dailyRank ?? 0)", color: .white)
                                DominionStat(label: "VANTAGE", value: viewModel.userProfile?.isRisingStar == true ? "RISING_STAR" : (viewModel.userProfile?.level ?? 0 >= 10 ? "ELITE" : "INIT"), color: .purple)
                            }
                            
                            // Territory Growth Bar
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("ZONE_DOMINATION")
                                        .font(.system(size: 7, weight: .black, design: .monospaced))
                                    Spacer()
                                    Text("\(viewModel.userProfile?.xp ?? 0 > 0 ? "1%" : "0%")")
                                        .font(.system(size: 7, weight: .black, design: .monospaced))
                                }
                                .foregroundColor(.white.opacity(0.6))
                                
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                                    Capsule()
                                        .fill(AppDesignSystem.Colors.primaryGradient)
                                        .frame(width: viewModel.userProfile?.xp ?? 0 > 0 ? 10 : 0, height: 4)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                        
                        // Action Buttons - Strategic Move (Withdrawals/Linking)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("FINANCIAL_LOGISTICS")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if viewModel.userProfile?.payoutStatus == "active" {
                                        Task { await viewModel.withdrawFunds() }
                                    } else {
                                        Task { await viewModel.linkBank() }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "bolt.horizontal.fill")
                                        Text(viewModel.userProfile?.payoutStatus == "active" ? "STRATEGIC_PAYOUT" : "INIT_BANK_LINK")
                                    }
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.userProfile?.revenueCents ?? 0 > 0 || viewModel.userProfile?.payoutStatus != "active" ? Color.cyan : Color.white.opacity(0.1))
                                    .foregroundColor(viewModel.userProfile?.revenueCents ?? 0 > 0 || viewModel.userProfile?.payoutStatus != "active" ? .black : .white.opacity(0.3))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // PREDICTIVE_RANKING (v3 AI Insight)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.cyan)
                                Text("PREDICTIVE_AI_INSIGHT")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            
                            Text("PROJECTION: \(viewModel.userProfile?.isRisingStar == true ? "You are a RISING STAR. Significant growth projected." : "Trend analysis active in \(viewModel.userProfile?.cityName?.uppercased() ?? "CURRENT_ZONE"). Upload content to trigger 'World Domination' glow.")")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(Color.cyan.opacity(0.05))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Prize Pool Info (Competitive v3)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("NEURAL_REPUTATION_TIERS")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            VStack(spacing: 12) {
                                PrizeRow(rank: 1, amount: "$1,000", label: "NEURAL_CROWN (WORLD)")
                                PrizeRow(rank: 2, amount: "$500", label: "ELITE_TIER (REGION)")
                                PrizeRow(rank: 3, amount: "$200", label: "VANTAGE_TIER (CITY)")
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingOnboarding) {
            if let url = viewModel.onboardingURL {
                StripeOnboardingView(url: url)
            }
        }
        .alert("Neural Sync Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("Roger That", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error in HQ protocols.")
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(1.5)
                Text("ESTABLISHING_SECURE_LINK...")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
    }
}

struct DominionStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 6, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NeuralBankView()
}

struct PrizeRow: View {
    let rank: Int
    let amount: String
    let label: String
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(rank <= 3 ? (rank == 1 ? .yellow : .pink) : .white.opacity(0.4))
                .frame(width: 30, alignment: .leading)
            
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.cyan)
        }
    }
}
