import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingStoryViewer = false
    @State private var showingNeuralBank = false
    @State private var selectedVideo: AppVideo? = nil
    
    enum ProfileTab {
        case posts, calendar, likes
    }
    
    @State private var selectedTab: ProfileTab = .posts
    
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile Hero Section - 2.0 Immersive
                    ZStack {
                        // Background Blur Layer
                        AppAvatar(url: viewModel.userProfile?.avatarURL, size: 300, hasStories: viewModel.hasActiveStories, isUploading: viewModel.isUploading)
                            .blur(radius: 60)
                            .opacity(0.15)
                            .offset(y: -100)
                        
                        VStack(spacing: 22) {
                            ZStack(alignment: .bottomTrailing) {
                                Button(action: {
                                    if viewModel.hasActiveStories {
                                        showingStoryViewer = true
                                    }
                                }) {
                                    AppAvatar(url: viewModel.userProfile?.avatarURL, size: 110, hasStories: viewModel.hasActiveStories, isUploading: viewModel.isUploading)
                                        .shadow(color: viewModel.hasActiveStories ? Color.purple.opacity(0.6) : Color(hex: "FF0080").opacity(0.4), radius: 30)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { showingEditProfile = true }) {
                                    Circle()
                                        .fill(AppDesignSystem.Colors.primaryGradient)
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        )
                                        .shadow(radius: 5)
                                }
                                .offset(x: 4, y: 4)
                            }
                            
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
                                
                                // Next Gen XP HUD
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
                            
                            // Action Buttons - Premium Glass 2.0
                            HStack(spacing: 12) {
                                Button(action: { showingEditProfile = true }) {
                                    Text("Edit profile")
                                        .font(.system(size: 15, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(.ultraThinMaterial.opacity(0.5))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1))
                                }
                                .foregroundColor(.white)
                                
                                if let username = viewModel.userProfile?.username {
                                    ShareLink(
                                        item: URL(string: "https://trueworldapp.com/u/\(username)")!,
                                        subject: Text("Check out my Trueworld Profile"),
                                        message: Text("Join me on Trueworld 2.0 and witness the neural future. @\(username)"),
                                        preview: SharePreview("@\(username) Trueworld Profile", image: Image(systemName: "person.circle.fill"))
                                    ) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(14)
                                            .background(.ultraThinMaterial.opacity(0.5))
                                            .cornerRadius(16)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1))
                                    }
                                    .foregroundColor(.white)
                                }
                                
                                Button(action: { /* Save action */ }) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(14)
                                        .background(.ultraThinMaterial.opacity(0.5))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1))
                                }
                                .foregroundColor(.white)
                                
                                Button(action: { showingNeuralBank = true }) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(14)
                                        .background(.ultraThinMaterial.opacity(0.5))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1))
                                }
                                .foregroundColor(.cyan)
                                
                                Button(action: { showingSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding(14)
                                        .background(.ultraThinMaterial.opacity(0.5))
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1))
                                }
                                .foregroundColor(.white)
                            }
                            .padding(.horizontal, 24)
                            
                            if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 45)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.top, 70)
                        .padding(.bottom, 30)
                    }
                    
                    // Content Tabs - Redesigned with matchedGeometry
                    HStack(spacing: 0) {
                        ForEach([ProfileTab.posts, .calendar, .likes], id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                TabIcon(
                                    systemName: iconForTab(tab),
                                    isActive: selectedTab == tab,
                                    namespace: profileTabNamespace,
                                    underlineId: "profile_tab_underline"
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.03))
                    
                    // Dynamic Content Area
                    VStack {
                        switch selectedTab {
                        case .posts:
                            VideoGridView(
                                videos: viewModel.userVideos,
                                emptyMessage: "No videos uploaded yet",
                                onVideoTap: { video in
                                    selectedVideo = video
                                }
                            )
                        case .calendar:
                            PostingTimelineView(
                                videos: viewModel.userVideos,
                                onVideoTap: { video in
                                    selectedVideo = video
                                }
                            )
                        case .likes:
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
        .task {
            await viewModel.fetchProfile()
        }
        .fullScreenCover(isPresented: $showingEditProfile) {
            if let user = viewModel.userProfile {
                EditProfileView(viewModel: EditProfileViewModel(user: user))
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $selectedVideo, onDismiss: {
            Task { await viewModel.fetchProfile() }
        }) { video in
            VideoDetailView(videoId: video.id)
        }
        .fullScreenCover(isPresented: $showingStoryViewer) {
            StoryViewer(stories: viewModel.activeStories, isPresented: $showingStoryViewer)
        }
        .fullScreenCover(isPresented: $showingNeuralBank) {
            NeuralBankView()
        }
    }
    
    @Namespace private var profileTabNamespace
    
    private func iconForTab(_ tab: ProfileTab) -> String {
        switch tab {
        case .posts: return "squareshape.split.3x3"
        case .calendar: return "calendar"
        case .likes: return "heart.fill"
        }
    }
    
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


#Preview {
    NavigationView {
        ProfileView()
    }
}

