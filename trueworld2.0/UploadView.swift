import SwiftUI
import PhotosUI

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppDesignSystem.Components.DynamicBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        headerSection
                        
                        VStack(spacing: 20) {
                            videoSelectorSection
                            metadataSection
                        }
                        
                        uploadButtonSection
                    }
                }
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.reset()
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .alert("Upload Success", isPresented: $viewModel.uploadSuccess) {
                Button("Great") { 
                    viewModel.reset()
                }
            } message: {
                Text("Your video is now live on Trueworld 2.0!")
            }
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.badge.plus.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppDesignSystem.Colors.primaryGradient)
                .shadow(color: Color(hex: "FF0080").opacity(0.3), radius: 15)
            
            Text("Share your vibe")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var videoSelectorSection: some View {
        PhotosPicker(selection: $viewModel.selectedItem, 
                    matching: viewModel.isPostAsStory ? .any(of: [.videos, .images]) : .videos) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 2)
                    .background(Color.white.opacity(0.05))
                    .frame(height: 180)
                
                if viewModel.selectedItem != nil {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                        Text("Video Selected")
                            .font(.headline)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "video.fill")
                            .font(.title)
                        Text("Tap to select video")
                            .font(.headline)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
        VStack(spacing: 16) {
            CustomTextField(placeholder: "Tell us about this...", text: $viewModel.videoDescription, icon: "text.alignleft")
                .glassy(cornerRadius: 16)
            
            CustomTextField(placeholder: "Music name", text: $viewModel.musicTitle, icon: "music.note")
                 .glassy(cornerRadius: 16)
             
             // Story Options
             VStack(spacing: 12) {
                 Toggle(isOn: $viewModel.isPostAsStory) {
                     VStack(alignment: .leading, spacing: 2) {
                         Text("STORY MODE")
                             .font(.system(size: 8, weight: .black, design: .monospaced))
                             .foregroundColor(.purple)
                         Text("Expires in 24 hours")
                             .font(.system(size: 10, weight: .medium))
                             .foregroundColor(.white.opacity(0.5))
                     }
                 }
                 .tint(.purple)
                 
                 if viewModel.isPostAsStory {
                     Divider().background(Color.white.opacity(0.1))
                     
                     Toggle(isOn: $viewModel.isLockedStory) {
                         VStack(alignment: .leading, spacing: 2) {
                             Text("EXCLUSIVE CONTENT")
                                 .font(.system(size: 8, weight: .black, design: .monospaced))
                                 .foregroundColor(.orange)
                             Text("Fans must pay to unlock")
                                 .font(.system(size: 10, weight: .medium))
                                 .foregroundColor(.white.opacity(0.5))
                         }
                     }
                     .tint(.orange)
                     
                     if viewModel.isLockedStory {
                         HStack {
                             Text("Price (USD)")
                                 .font(.system(size: 12, weight: .bold))
                                 .foregroundColor(.white)
                             Spacer()
                             TextField("0.00", value: $viewModel.storyPrice, format: .currency(code: "USD"))
                                 .keyboardType(.decimalPad)
                                 .multilineTextAlignment(.trailing)
                                 .foregroundColor(.orange)
                                 .font(.system(size: 16, weight: .black))
                         }
                         .padding(.top, 4)
                     }
                 }
             }
             .padding()
             .glassy(cornerRadius: 16)
             .overlay(RoundedRectangle(cornerRadius: 16).stroke(viewModel.isPostAsStory ? Color.purple.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1))
             
             // Location Tagging Section
             VStack(alignment: .leading, spacing: 12) {
                 HStack {
                     VStack(alignment: .leading, spacing: 2) {
                         HStack(spacing: 4) {
                             Circle()
                                 .fill(viewModel.isLocating ? Color.cyan : Color.green)
                                 .frame(width: 6, height: 6)
                                 .opacity(viewModel.isLocating ? 0.5 : 1.0)
                             Text("SUPERGEN AI LOCATOR V4.1")
                                 .font(.system(size: 8, weight: .black, design: .monospaced))
                                 .foregroundColor(.cyan)
                         }
                         Text(viewModel.latitude != nil ? "LOCATION: \(viewModel.locationName?.uppercased() ?? "SYNCED")" : "LOCATION: OFFLINE")
                             .font(.system(size: 14, weight: .bold, design: .rounded))
                             .foregroundColor(.white)
                     }
                     
                     Spacer()
                     
                     if viewModel.isLocating {
                         LocationScannerEffect()
                             .frame(width: 30, height: 30)
                     } else if viewModel.latitude != nil {
                         Image(systemName: "antenna.radiowaves.left.and.right")
                             .foregroundColor(.green)
                             .font(.system(size: 14))
                             .shadow(color: .green.opacity(0.5), radius: 5)
                     }
                 }
                 
                 Button(action: {
                     viewModel.requestLocation()
                     let generator = UIImpactFeedbackGenerator(style: .medium)
                     generator.impactOccurred()
                 }) {
                     HStack {
                         Image(systemName: viewModel.latitude != nil ? "mappin.and.ellipse" : "location.circle.fill")
                             .font(.system(size: 16))
                         
                         Text(viewModel.latitude != nil ? "Recalibrate AI GPS" : "Sync True World Neural Link")
                             .font(.system(size: 13, weight: .bold))
                         
                         Spacer()
                         
                         if viewModel.latitude != nil {
                             Image(systemName: "checkmark.seal.fill")
                                 .foregroundColor(.cyan)
                         }
                     }
                     .foregroundColor(.white)
                     .padding(.vertical, 12)
                     .padding(.horizontal, 16)
                     .background(Color.white.opacity(0.1))
                     .cornerRadius(12)
                     .overlay(
                         RoundedRectangle(cornerRadius: 12)
                             .stroke(Color.white.opacity(0.1), lineWidth: 1)
                     )
                 }
                 
                 // AI Privacy Guard Toggle
                 Toggle(isOn: $viewModel.isPrivacyGuardEnabled) {
                     VStack(alignment: .leading, spacing: 2) {
                         Text("TRUE WORLD PRIVACY GUARD")
                             .font(.system(size: 8, weight: .black, design: .monospaced))
                             .foregroundColor(.pink)
                         Text("Neural Location Jitter (500m Safe Zone)")
                             .font(.system(size: 10, weight: .medium))
                             .foregroundColor(.white.opacity(0.5))
                     }
                 }
                 .tint(.pink)
                 .padding(.top, 4)
             }
             .padding()
             .glassy(cornerRadius: 24)
             .overlay(
                 RoundedRectangle(cornerRadius: 24)
                     .stroke(viewModel.isPrivacyGuardEnabled ? Color.pink.opacity(0.2) : Color.cyan.opacity(0.2), lineWidth: 1)
             )
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var uploadButtonSection: some View {
        if viewModel.isUploading {
            VStack(spacing: 15) {
                ProgressView(value: viewModel.uploadProgress)
                    .accentColor(Color(hex: "FF0080"))
                    .padding(.horizontal, 40)
                
                Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 40)
            .padding(.bottom, 120)
        } else {
            Button(action: {
                Task {
                    await viewModel.uploadMedia()
                }
            }) {
                Text(viewModel.isPostAsStory ? "Share Story" : "Post Video")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppDesignSystem.Colors.primaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "FF0080").opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 120)
            .disabled(viewModel.selectedItem == nil)
        }
    }
}

struct LocationScannerEffect: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                .scaleEffect(animate ? 1.5 : 0.8)
                .opacity(animate ? 0 : 1)
            
            Circle()
                .fill(Color.cyan.opacity(0.2))
                .frame(width: 10, height: 10)
                .scaleEffect(animate ? 0.5 : 1.2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    UploadView()
}
