import SwiftUI

struct PrivacyPolicyView: View {
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
                    
                    Text("Privacy Policy")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your Neural Privacy Matters")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Last Updated: March 2026")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Group {
                            Text("1. Data Collection")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Trueworld 2.0 collects real-time location pings to populate the iWorld (Eye World) global neural map. This data is handled via Supabase Auth and Realtime channels to ensure a fluid, living network.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Group {
                            Text("2. Location Masking")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("You have the right to cloak your neural signature. Enabling 'Private Account' in Privacy Settings will obscure your real-time position from the global pulse.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Group {
                            Text("3. Financial Privacy")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Bank account details provided for Stripe Connect are processed directly by Stripe. Trueworld 2.0 does not store raw banking credentials.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Group {
                            Text("4. Eye World (iWorld) Synchronicity")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("The Eye World (iWorld) interface uses high-precision neural scanning to facilitate the 'AI Locator' and 'Global Pulse' features. Location data is streamed via encrypted Realtime channels to calculate proximity and global rankings. This data is transient and used solely to synchronize your presence within the neural map.")
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
