import Combine
import Supabase
import Foundation
import SwiftUI
import Realtime

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Use RealtimeV2 channels via the client when subscribing (created per-task)
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = iso.date(from: dateStr) { return date }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let d = df.date(from: dateStr) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateStr)")
        }
        return decoder
    }
    
    func fetchNotifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = SupabaseManager.shared.client
            let user = try await client.auth.session.user
            
            // Join with profiles to get actor details
            let response = try await client
                .database
                .from("notifications")
                .select("*, actor:profiles!actor_id(username, avatar_url)")
                .eq("user_id", value: user.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let fetched = try decoder.decode([AppNotification].self, from: response.data)
            self.notifications = fetched
            
            updateGlobalUnreadCount()
            setupRealtimeSubscription(userId: user.id)
        } catch {
            print("Error fetching notifications: \(error)")
            self.errorMessage = "Unable to load activity. Please try again."
            self.notifications = []
        }
        
        isLoading = false
    }
    
    private func setupRealtimeSubscription(userId: UUID) {
        let client = SupabaseManager.shared.client

        let channel = client.realtime.channel("public:notifications")

        channel.on("postgres_changes", filter: ChannelFilter(event: "INSERT", schema: "public", table: "notifications", filter: "user_id=eq.\(userId.uuidString)")) { [weak self] _ in
            Task { @MainActor [weak self] in
                // When a new notification arrives, refetch to get actor details
                await self?.fetchNotifications()
                
                // Present the top one if it's new
                if let first = self?.notifications.first {
                    NotificationManager.shared.present(first)
                }
            }
        }

        channel.subscribe()
    }
    
    private func handleInsert(_ action: InsertAction) async {
        do {
            let recordData = try JSONEncoder().encode(action.record)
            let newNotification = try decoder.decode(AppNotification.self, from: recordData)
            
            withAnimation {
                self.notifications.insert(newNotification, at: 0)
            }
            updateGlobalUnreadCount()
            NotificationManager.shared.present(newNotification)
        } catch {
            print("Error decoding inserted notification: \(error)")
        }
    }
    
    private func handleUpdate(_ action: UpdateAction) async {
        do {
            let recordData = try JSONEncoder().encode(action.record)
            let updated = try decoder.decode(AppNotification.self, from: recordData)
            
            if let index = notifications.firstIndex(where: { $0.id == updated.id }) {
                withAnimation {
                    self.notifications[index] = updated
                }
            }
            updateGlobalUnreadCount()
        } catch {
            print("Error decoding updated notification: \(error)")
        }
    }
    
    private func handleDelete(_ action: DeleteAction) async {
        var idString: String? = nil
        
        if let idValue = action.oldRecord["id"] {
            if let s = idValue as? String {
                idString = s
            } else if let u = idValue as? UUID {
                idString = u.uuidString
            } else {
                // Fallback to string description for other types (Int, Double, etc.)
                idString = "\(idValue)"
            }
        }
        
        if let s = idString, let id = UUID(uuidString: s) {
            withAnimation {
                self.notifications.removeAll(where: { $0.id == id })
            }
        }
        updateGlobalUnreadCount()
    }
    
    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        
        do {
            let client = SupabaseManager.shared.client
            try await client
                .database
                .from("notifications")
                .update(["is_read": true])
                .eq("id", value: notification.id.uuidString)
                .execute()
            
            // Local update for immediate feedback
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
                updateGlobalUnreadCount()
            }
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        let unreadIds = notifications.filter { !$0.isRead }.map { $0.id.uuidString }
        guard !unreadIds.isEmpty else { return }
        
        do {
            let client = SupabaseManager.shared.client
            try await client
                .database
                .from("notifications")
                .update(["is_read": true])
                .in("id", value: unreadIds)
                .execute()
            
            // Local update
            for i in 0..<notifications.count {
                notifications[i].isRead = true
            }
            updateGlobalUnreadCount()
        } catch {
            print("Error marking all as read: \(error)")
        }
    }
    
    private func updateGlobalUnreadCount() {
        NotificationManager.shared.updateUnreadCount(unreadCount)
    }
    
    deinit {}
}
