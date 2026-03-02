import SwiftUI

struct TermsOfServiceView: View {
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
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Terms of Service")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Welcome to Trueworld 2.0")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Last Updated: March 2026")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Group {
                            Text("1. Acceptance of Terms")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("By accessing the Trueworld 2.0 neural network, you agree to be bound by these terms. If you do not agree, disconnect immediately.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Group {
                            Text("2. User Identity & Content")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("You are responsible for your global identity and any content you broadcast. Trueworld 2.0 reserves the right to terminate any neural link that violates community standards.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Group {
                            Text("3. Monetization & Earnings")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Creators acknowledge that revenue is generated through neural engagement and is subject to local financial regulations. Payouts are handled via simulated Stripe Connect for V1 testing.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Group {
                            Text("4. Neural Privacy")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("While we aim for maximum fluidity, your data is processed through decentralized edge functions. Use private mode if you wish to cloak your location on the global map.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
