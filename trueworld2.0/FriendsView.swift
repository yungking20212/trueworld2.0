import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var selectedTab: SocialTab = .suggested
    
    enum SocialTab: String, CaseIterable {
        case suggested = "Suggested"
        case aiNews = "AI News"
        case following = "Following"
        case followers = "Followers"
    }
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                customTabBar
                
                contentView
            }
        }
        .task {
            await viewModel.fetchSocialHub()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Social Hub")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Integrated Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                
                TextField("Search creators...", text: $viewModel.searchQuery)
                    .foregroundColor(.white)
                    .tint(AppDesignSystem.Colors.vibrantPink)
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .padding(.horizontal)
        }
        .padding(.top, 20)
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(SocialTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.4))
                        
                        ZStack {
                            Capsule()
                                .fill(Color.clear)
                                .frame(height: 3)
                            
                            if selectedTab == tab {
                                Capsule()
                                    .fill(AppDesignSystem.Colors.primaryGradient)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "tab_underline", in: tabNamespace)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
    
    @Namespace private var tabNamespace
    
    @ViewBuilder
    private var contentView: some View {
        if !viewModel.searchQuery.isEmpty {
            searchListView
        } else {
            switch selectedTab {
            case .suggested:
                suggestedListView
            case .aiNews:
                AINewsView()
            case .following:
                followingListView
            case .followers:
                followersListView
            }
        }
    }
    
    private var suggestedListView: some View {
        ScrollView {
            VStack(spacing: 25) {
                if !viewModel.trendingCreators.isEmpty {
                    TrendingCreatorsView(creators: viewModel.trendingCreators)
                        .padding(.top, 10)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("People you may know")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.suggestedUsers) { user in
                            FriendRow(
                                user: user,
                                isFollowing: viewModel.followingIds.contains(user.id),
                                onToggle: {
                                    Task { await viewModel.toggleFollow(for: user.id) }
                                },
                                onPing: {
                                    Task { await viewModel.sendNeuralPing(to: user.id) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 120)
        }
        .refreshable {
            await viewModel.fetchSocialHub()
        }
    }
    
    private var followingListView: some View {
        Group {
            if viewModel.followingUsers.isEmpty {
                emptyState(icon: "person.badge.plus", text: "You aren't following anyone yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.followingUsers) { user in
                            FriendRow(
                                user: user,
                                isFollowing: true,
                                onToggle: {
                                    Task { await viewModel.toggleFollow(for: user.id) }
                                },
                                onPing: {
                                    Task { await viewModel.sendNeuralPing(to: user.id) }
                                }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var followersListView: some View {
        Group {
            if viewModel.followersUsers.isEmpty {
                emptyState(icon: "person.2.fill", text: "No followers yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.followersUsers) { user in
                            FriendRow(
                                user: user,
                                isFollowing: viewModel.followingIds.contains(user.id),
                                onToggle: {
                                    Task { await viewModel.toggleFollow(for: user.id) }
                                },
                                onPing: {
                                    Task { await viewModel.sendNeuralPing(to: user.id) }
                                }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var searchListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.searchResults) { user in
                    FriendRow(
                        user: user,
                        isFollowing: viewModel.followingIds.contains(user.id),
                        onToggle: {
                            Task { await viewModel.toggleFollow(for: user.id) }
                        },
                        onPing: {
                            Task { await viewModel.sendNeuralPing(to: user.id) }
                        }
                    )
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.15))
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }
}

struct FriendRow: View {
    let user: AppUser
    let isFollowing: Bool
    let onToggle: () -> Void
    let onPing: () -> Void
    
    var body: some View {
        NavigationLink(destination: PeerProfileView(viewModel: PeerProfileViewModel(userId: user.id))) {
            HStack(spacing: 15) {
                AppAvatar(url: user.avatarURL, size: 54)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(user.fullName ?? user.username ?? "Anonymous")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if user.followerCount > 100 {
                        Text("Suggested Creator")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppDesignSystem.Colors.vibrantPink.opacity(0.1))
                            .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                            .cornerRadius(4)
                    }
                    
                    Text("@\(user.username ?? "user")")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 8) {
                        Label(formatCount(user.followerCount), systemImage: "person.2.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                        
                        if let bio = user.bio, !bio.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.1))
                            Text(bio)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                                .lineLimit(1)
                        }
                    }
                }
                
                
                Spacer()
                
                // Neural Ping Button
                Button(action: onPing) {
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppDesignSystem.Colors.vibrantBlue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(8)
                        .background(AppDesignSystem.Colors.vibrantBlue.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppDesignSystem.Colors.vibrantBlue.opacity(0.3), lineWidth: 1))
                }
                .padding(.trailing, 4)
                
                Button(action: onToggle) {
                        Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if isFollowing {
                                    Color.white.opacity(0.1)
                                } else {
                                    AppDesignSystem.Colors.primaryGradient
                                }
                            }
                        )
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.2), lineWidth: isFollowing ? 1 : 0)
                        )
                }
                .foregroundColor(isFollowing ? .white.opacity(0.6) : .white)
            }
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.2))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

#Preview {
    FriendsView()
}
