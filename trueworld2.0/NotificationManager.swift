import SwiftUI
import Combine
import Auth
import Supabase

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var latestNotification: AppNotification?
    @Published var showBanner = false
    @Published var apnsToken: String?
    
    private var bannerTimer: Timer?
    
    // Total unread count for global tab bar badge
    @Published var unreadCount: Int = 0
    
    private init() {}
    
    func setAPNSToken(_ token: String) async {
        self.apnsToken = token
        await syncTokenWithSupabase()
    }
    
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification permission granted.")
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    func syncTokenWithSupabase() async {
        guard let token = apnsToken else { return }
        
        do {
            let client = SupabaseManager.shared.client
            let user = try await client.auth.session.user
            
            try await client.database
                .from("profiles")
                .update(["apns_token": token])
                .eq("id", value: user.id.uuidString)
                .execute()
            
            print("Successfully synced APNs token with Supabase.")
        } catch {
            let errString = "\(error)"
            if errString.contains("PGRST204") {
                // Column missing - ignore silently as it's a known schema limitation
                return
            }
            print("Error syncing APNs token: \(error)")
        }
    }
    
    func present(_ notification: AppNotification) {
        withAnimation(.spring()) {
            self.latestNotification = notification
            self.showBanner = true
        }
        
        // Auto-dismiss after 4 seconds
        bannerTimer?.invalidate()
        bannerTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation(.spring()) {
                    self?.showBanner = false
                }
            }
        }
    }
    
    func updateUnreadCount(_ count: Int) {
        self.unreadCount = count
    }
}

struct InAppNotificationBanner: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primaryGradient.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.actor?.username ?? "Someone")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(activityDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .onTapGesture {
            onDismiss()
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
        case "neural_ping": return "sent you a neural pulse"
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
        case "neural_ping": return "bolt.horizontal.circle.fill"
        default: return "bell.fill"
        }
    }
}
