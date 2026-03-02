import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Welcome to Trueworld")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Let's set up your profile")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 60)
                    
                    // Avatar Selection
                    PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let data = viewModel.avatarData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                            }
                            
                            Circle()
                                .fill(AppDesignSystem.Colors.primaryGradient)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: -5, y: -5)
                        }
                    }
                    .onChange(of: viewModel.selectedItem) { _ in
                        Task { await viewModel.handleImageSelection() }
                    }
                    
                    // Fields
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "Username", text: $viewModel.username, icon: "at")
                            .glassy(cornerRadius: 16)
                        
                        CustomTextField(placeholder: "Full Name", text: $viewModel.fullName, icon: "person")
                            .glassy(cornerRadius: 16)
                        
                        CustomTextField(placeholder: "Bio", text: $viewModel.bio, icon: "text.quote")
                            .glassy(cornerRadius: 16)
                    }
                    .padding(.horizontal, 30)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.saveProfile()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppDesignSystem.Colors.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 30)
                    .disabled(viewModel.isLoading)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
