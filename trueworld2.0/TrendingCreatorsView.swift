import SwiftUI

struct TrendingCreatorsView: View {
    let creators: [AppUser]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Trending Creators")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(creators) { creator in
                        NavigationLink(destination: PeerProfileView(viewModel: PeerProfileViewModel(userId: creator.id))) {
                            TrendingCreatorCard(creator: creator)
                                .overlay(
                                    VStack {
                                        if creator.followerCount > 1000 {
                                            Text("VIBRANT")
                                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(AppDesignSystem.Colors.vibrantPink)
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                                .offset(y: -10)
                                        }
                                        Spacer()
                                    }
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10) // Extra room for the VIBRANT badge
                .padding(.bottom, 10)
            }
        }
    }
}

struct TrendingCreatorCard: View {
    let creator: AppUser
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primaryGradient)
                    .frame(width: 84, height: 84)
                    .blur(radius: 8)
                    .opacity(0.3)
                
                AppAvatar(url: creator.avatarURL, size: 80)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
            }
            
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(creator.fullName ?? creator.username ?? "Anonymous")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if creator.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(formatCount(creator.followerCount) + " followers")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                
                // XP Level Badge
                HStack(spacing: 4) {
                    Text("LEVEL \(creator.level)")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .cornerRadius(4)
                }
                .padding(.top, 2)
            }
            .frame(width: 90)
        }
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
