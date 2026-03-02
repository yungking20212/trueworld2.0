import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Activity")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    
                    if !viewModel.notifications.isEmpty && viewModel.unreadCount > 0 {
                        Button(action: {
                            Task { await viewModel.markAllAsRead() }
                        }) {
                            Text("Mark all read")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 50)
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No new activity")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 100)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRow(notification: notification)
                                    .onTapGesture {
                                        Task { await viewModel.markAsRead(notification) }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.fetchNotifications()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchNotifications()
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Actor Avatar
            AppAvatar(url: notification.actor?.avatarURL, size: 48)
                .overlay(alignment: .bottomTrailing) {
                    notificationIcon
                        .frame(width: 20, height: 20)
                        .background(Color.black)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(notification.actor?.username ?? "Someone")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(activityDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(timeAgo)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // Interaction Indicator (Unread)
            if !notification.isRead {
                Circle()
                    .fill(AppDesignSystem.Colors.vibrantBlue)
                    .frame(width: 8, height: 8)
                    .shadow(color: AppDesignSystem.Colors.vibrantBlue.opacity(0.5), radius: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(notification.isRead ? 0.3 : 0.6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(notification.isRead ? Color.white.opacity(0.05) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(iconColor)
            
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var activityDescription: String {
        switch notification.type {
        case "like": return "liked your video"
        case "comment": return "commented on your post"
        case "follow": return "started following you"
        case "mention": return "mentioned you in a post"
        case "message": return "sent you a message"
        case "repost": return "reposted your video"
        default: return "interacted with you"
        }
    }
    
    private var iconName: String {
        switch notification.type {
        case "like": return "heart.fill"
        case "comment": return "bubble.right.fill"
        case "follow": return "person.fill.badge.plus"
        case "mention": return "at"
        case "message": return "envelope.fill"
        case "repost": return "arrow.2.squarepath"
        default: return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case "like": return .pink
        case "comment": return .blue
        case "follow": return .purple
        case "mention": return .orange
        case "message": return .green
        case "repost": return .cyan
        default: return .gray
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }
}
