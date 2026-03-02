import SwiftUI

struct SupportView: View {
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
                    
                    Text("Support Hub")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSection(title: "Get Help") {
                            SettingsRow(icon: "lifepreserver.fill", title: "Help Center")
                            NavigationLink(destination: SupportTicketView()) {
                                SettingsRow(icon: "envelope.fill", title: "Contact Support")
                            }
                            NavigationLink(destination: ReportProblemView()) {
                                SettingsRow(icon: "exclamationmark.triangle.fill", title: "Report a Problem")
                            }
                        }
                        
                        SettingsSection(title: "Legal") {
                            SettingsRow(icon: "doc.text.fill", title: "Terms of Service")
                            SettingsRow(icon: "shield.righthalf.filled", title: "Privacy Policy")
                            SettingsRow(icon: "hammer.fill", title: "Community Guidelines")
                        }
                        
                        VStack(spacing: 8) {
                            Text("Trueworld 2.0")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Version 1.0.0 (Build 2026)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.top, 40)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
