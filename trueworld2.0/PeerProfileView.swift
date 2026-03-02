import SwiftUI

struct PeerProfileView: View {
    @StateObject var viewModel: PeerProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedVideo: AppVideo? = nil
    @State private var selectedTab: ProfileTab = .posts
    
    enum ProfileTab {
        case posts, likes
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Navigation Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Text(viewModel.userProfile?.username ?? "Creator")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 50) // Absolute clearance for notch
                .padding(.bottom, 12)
                .background(.black.opacity(0.2))
                
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Hero Section - 2.0 Immersive
                    ZStack {
                        // Background Blur Layer
                        AppAvatar(url: viewModel.userProfile?.avatarURL, size: 300)
                            .blur(radius: 60)
                            .opacity(0.15)
                            .offset(y: -50)
                        
                        VStack(spacing: 22) {
                            AppAvatar(url: viewModel.userProfile?.avatarURL, size: 110)
                                .overlay(Circle().stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 2))
                                .shadow(color: Color(hex: "FF0080").opacity(0.4), radius: 30)
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(viewModel.userProfile?.fullName ?? "Trueworld User")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    if viewModel.userProfile?.isVerified == true {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .shadow(color: .black.opacity(0.3), radius: 10)
                                
                                Text("@\(viewModel.userProfile?.username ?? "user")")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                // Next Gen XP HUD (Neural Presence)
                                if let user = viewModel.userProfile {
                                    VStack(spacing: 6) {
                                        HStack {
                                            Text("LEVEL \(user.level)")
                                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                                .foregroundColor(.cyan)
                                            
                                            Spacer()
                                            
                                            Text("\(user.xp) XP")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        .frame(width: 200)
                                        
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 200, height: 6)
                                            
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.cyan, .blue],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: 200 * CGFloat(user.xpProgress), height: 6)
                                                .shadow(color: .cyan.opacity(0.5), radius: 6)
                                                .animation(.interpolatingSpring(stiffness: 50, damping: 10).delay(0.2), value: user.xpProgress)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            HStack(spacing: 35) {
                                StatView(count: formatCount(viewModel.followingCount), label: "Following")
                                StatView(count: formatCount(viewModel.followersCount), label: "Followers")
                                StatView(count: formatCount(viewModel.totalLikes), label: "Likes")
                            }
                            
                            // Action Button - Premium Vantage 2.0
                            HStack(spacing: 12) {
                                Button(action: {
                                    if viewModel.isCurrentUser {
                                        // Could trigger edit profile or just show it's you
                                    } else {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        Task { await viewModel.toggleFollow() }
                                    }
                                }) {
                                    Text(viewModel.isCurrentUser ? "This is you" : (viewModel.isFollowing ? "Following" : "Follow"))
                                        .font(.system(size: 15, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(viewModel.isCurrentUser || viewModel.isFollowing ? AnyView(Color.white.opacity(0.1)) : AnyView(AppDesignSystem.Colors.primaryGradient))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1)
                                        )
                                }
                                .foregroundColor(.white)
                                .disabled(viewModel.isCurrentUser)
                                
                                if let username = viewModel.userProfile?.username {
                                    ShareLink(
                                        item: URL(string: "https://trueworldapp.com/u/\(username)")!,
                                        subject: Text("Check out @\(username) on Trueworld"),
                                        message: Text("Witness the neural future of @\(username) on Trueworld 2.0."),
                                        preview: SharePreview("@\(username) Trueworld Profile", image: Image(systemName: "person.circle.fill"))
                                    ) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 15, weight: .bold))
                                            .padding(14)
                                            .background(.ultraThinMaterial.opacity(0.1))
                                            .cornerRadius(16)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 40)
                            
                            if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 45)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                    }
                    
                    // Content Tabs - Redesigned with matchedGeometry
                    HStack(spacing: 0) {
                        ForEach([ProfileTab.posts, .likes], id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                TabIcon(
                                    systemName: tab == .posts ? "squareshape.split.3x3" : "heart.fill",
                                    isActive: selectedTab == tab,
                                    namespace: peerProfileTabNamespace,
                                    underlineId: "peer_profile_tab_underline"
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.03))
                        
                        // Dynamic Content Area
                        VStack {
                            if selectedTab == .posts {
                                VideoGridView(
                                    videos: viewModel.userVideos,
                                    emptyMessage: "No videos yet",
                                    onVideoTap: { video in
                                        selectedVideo = video
                                    }
                                )
                            } else {
                                VideoGridView(
                                    videos: viewModel.likedVideos,
                                    emptyMessage: "No liked videos yet",
                                    onVideoTap: { video in
                                        selectedVideo = video
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchProfile()
        }
        .fullScreenCover(item: $selectedVideo, onDismiss: {
            Task { await viewModel.fetchProfile() }
        }) { video in
            VideoDetailView(videoId: video.id)
        }
    }
    
    @Namespace private var peerProfileTabNamespace
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }
}

// Shared components moved to ProfileComponents.swift

// VideoThumbnail is no longer used, replaced by VideoThumbnailView in VideoGridView
