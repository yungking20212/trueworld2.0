import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            // Premium Dynamic Background
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 12) {
                    Text("Trueworld 2.0")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "FF0080").opacity(0.3), radius: 10)
                    
                    Text(viewModel.isSignUp ? "Join the future of social" : "Welcome back to the future")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)
                
                // Form
                VStack(spacing: 24) {
                                CustomTextField(placeholder: "Email", text: $viewModel.email, icon: "envelope.fill")
                        .glassy(cornerRadius: 16)
                    
                                if viewModel.isSignUp {
                                    CustomTextField(placeholder: "Username", text: $viewModel.username, icon: "person.fill")
                                        .glassy(cornerRadius: 16)
                                }
                    
                    CustomTextField(placeholder: "Password", text: $viewModel.password, icon: "lock.fill", isSecure: true)
                        .glassy(cornerRadius: 16)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        Task {
                            if viewModel.isSignUp {
                                await viewModel.signUp()
                            } else {
                                await viewModel.signIn()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(viewModel.isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppDesignSystem.Colors.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "FF0080").opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Toggle Button
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.isSignUp.toggle()
                        viewModel.errorMessage = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(viewModel.isSignUp ? "Already a member?" : "New here?")
                            .foregroundColor(.white.opacity(0.6))
                        Text(viewModel.isSignUp ? "Sign In" : "Create Account")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 14))
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    AuthView()
}
