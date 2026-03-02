import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPrivateAccount: Bool = false
    
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
                    
                    Text("Privacy & Safety")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSection(title: "Account Visibility") {
                            ToggleRow(icon: "lock.fill", title: "Private Account", isOn: $isPrivateAccount)
                                .onChange(of: isPrivateAccount) { newValue in
                                    Task {
                                        await viewModel.togglePrivacy(isPrivate: newValue)
                                    }
                                }
                            
                            p(text: "When your account is private, only people you approve can see your content.")
                        }
                        
                        SettingsSection(title: "Interactions") {
                            SettingsRow(icon: "message.fill", title: "Message Requests")
                            SettingsRow(icon: "hand.raised.fill", title: "Blocked Accounts")
                        }
                    }
                    .padding(.top, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isPrivateAccount = viewModel.userProfile?.isPrivate ?? false
        }
    }
    
    private func p(text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.4))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppDesignSystem.Colors.vibrantPink))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
