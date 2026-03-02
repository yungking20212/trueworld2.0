import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditProfileViewModel
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                    Spacer()
                    Text("Edit Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Button("Done") {
                            Task {
                                await viewModel.updateProfile()
                                if viewModel.isSuccess { dismiss() }
                            }
                        }
                        .font(.bold(.headline)())
                        .foregroundColor(Color(hex: "FF0080"))
                    }
                }
                .padding()
                .background(.black.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Avatar Edit
                        PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let data = viewModel.avatarData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    AppAvatar(url: viewModel.avatarURL, size: 100)
                                }
                                
                                Circle()
                                    .fill(AppDesignSystem.Colors.primaryGradient)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: -2, y: -2)
                            }
                        }
                        .padding(.top, 40)
                        .onChange(of: viewModel.selectedItem) { _ in
                            Task { await viewModel.handleImageSelection() }
                        }
                        
                        VStack(spacing: 20) {
                            AppDesignSystem.Components.AppEditField(title: "Username", text: $viewModel.username)
                            AppDesignSystem.Components.AppEditField(title: "Full Name", text: $viewModel.fullName)
                            AppDesignSystem.Components.AppEditField(title: "Bio", text: $viewModel.bio)
                        }
                        .padding(.horizontal)
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

