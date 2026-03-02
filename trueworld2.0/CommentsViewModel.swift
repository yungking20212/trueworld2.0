import Foundation
import Supabase
import SwiftUI
import Combine
import Realtime
internal import _Helpers

@MainActor
class CommentsViewModel: ObservableObject {
    let videoId: UUID
    @Published var comments: [AppComment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannel?
    
    init(videoId: UUID) {
        self.videoId = videoId
    }
    
    func fetchComments() async {
        isLoading = true
        errorMessage = nil

        do {
            await setupRealtimeSubscription()
            
            let response = try await client.database
                .from("video_comments")
                .select("*, author:profiles(username, avatar_url, follower_count)")
                .eq("video_id", value: videoId.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let dtos = try JSONDecoder().decode([AppCommentDTO].self, from: response.data)

            self.comments = dtos.map { $0.toAppComment() }
        } catch {
            print("Error fetching comments: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func setupRealtimeSubscription() async {
        // Avoid creating multiple channels
        if channel != nil { return }

        // Use the stable realtime v1 channel API (consistent with other view models)
        let ch = client.realtime.channel("public:video_comments:\(videoId.uuidString)")
        self.channel = ch

        ch.on("postgres_changes", filter: ChannelFilter(event: "*", schema: "public", table: "video_comments", filter: "video_id=eq.\(videoId.uuidString)")) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchComments()
            }
        }

        ch.subscribe()
    }
    
    func postComment(text: String, parentId: UUID? = nil) async {
        do {
            guard let user = try? await client.auth.session.user else { return }
            
            var commentData: [String: AnyJSON] = [
                "video_id": .string(videoId.uuidString),
                "user_id": .string(user.id.uuidString),
                "body": .string(text)
            ]
            if let parentId = parentId {
                commentData["parent_id"] = .string(parentId.uuidString)
            }
            
            try await client.database
                .from("video_comments")
                .insert(commentData)
                .execute()
            
        } catch {
            print("Error posting comment: \(error)")
        }
    }
    
    func likeComment(_ id: UUID) async {
        do {
            try await client.database.rpc("increment_comment_likes", params: ["c_id": id.uuidString]).execute()
            // Realtime update would ideally handle this, but if not, we can refetch or update locally
        } catch {
            print("Error liking comment: \(error)")
        }
    }
    
    deinit {
        channel?.unsubscribe()
    }
}

