import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
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
                    
                    Text("Notification Settings")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSection(title: "Global") {
                            HStack {
                                Text("Allow Push Notifications")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $viewModel.pushNotifications).tint(.blue)
                                    .labelsHidden()
                                    .onChange(of: viewModel.pushNotifications) { _ in
                                        Task { await viewModel.updateNotificationSettings() }
                                    }
                            }
                            .padding(20)
                        }
                        
                        SettingsSection(title: "Activity") {
                            HStack {
                                Text("Social Pings (Likes/Follows)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $viewModel.socialPings).tint(.pink)
                                    .labelsHidden()
                                    .onChange(of: viewModel.socialPings) { _ in
                                        Task { await viewModel.updateNotificationSettings() }
                                    }
                            }
                            .padding(20)
                            
                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 20)
                            
                            HStack {
                                Text("Neural Alerts (World Pulse)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $viewModel.neuralAlerts).tint(.cyan)
                                    .labelsHidden()
                                    .onChange(of: viewModel.neuralAlerts) { _ in
                                        Task { await viewModel.updateNotificationSettings() }
                                    }
                            }
                            .padding(20)
                        }
                        
                        SettingsSection(title: "Financial") {
                            HStack {
                                Text("Creator Payout Updates")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $viewModel.creatorPayouts).tint(.green)
                                    .labelsHidden()
                                    .onChange(of: viewModel.creatorPayouts) { _ in
                                        Task { await viewModel.updateNotificationSettings() }
                                    }
                            }
                            .padding(20)
                        }
                        
                        Text("Mute durations can be managed directly from the Activity feed.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
