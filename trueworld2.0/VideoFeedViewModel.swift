import Foundation
import Supabase
import SwiftUI
import Combine
import CoreLocation
import Realtime

@MainActor
class VideoFeedViewModel: ObservableObject {
    @Published var videos: [AppVideo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannel?
    private let locationManager = LocationManager.shared
    
    init() {
        setupRealtimeSubscription()
        locationManager.requestPermission()
        locationManager.startUpdating()
    }
    
    func setupRealtimeSubscription() {
        guard channel == nil else { return }
        
        // Listen for all new videos globally for real-time social vibe
        let channel = client.realtime.channel("public:videos:feed")
        self.channel = channel
        
        channel.on("postgres_changes", filter: ChannelFilter(event: "INSERT", schema: "public", table: "videos")) { [weak self] message in
            Task { @MainActor in
                 // When a new video is inserted, refetch the top of the feed
                 await self?.fetchVideos(loadMore: false)
            }
        }
        
        channel.subscribe()
    }
    
    func fetchVideos(loadMore: Bool = false) async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        
        let start = loadMore ? videos.count : 0
        let end = start + 9
        
        do {
            let response: PostgrestResponse = try await client
                .database
                .from("videos")
                .select("*, author:profiles!author_id(username, avatar_url, follower_count)")
                .range(from: start, to: end)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let videoDTOs = try decoder.decode([GlobalVideoMetadata].self, from: response.data)
            
            // Check current user likes
            let currentUser = try? await client.auth.session.user
            var likedVideoIds: Set<UUID> = []
            
            if let userId = currentUser?.id {
                let likesResponse = try await client
                    .database
                    .from("likes")
                    .select("video_id")
                    .eq("user_id", value: userId)
                    .execute()
                
                let decoder = JSONDecoder()
                let likesData = (try? decoder.decode([[String: UUID]].self, from: likesResponse.data)) ?? []
                likedVideoIds = Set(likesData.compactMap { $0["video_id"] })
            }
            
            let newVideos = videoDTOs.map { dto in
                AppVideo(
                    id: dto.id,
                    videoURL: dto.videoURL,
                    username: dto.username,
                    description: dto.description,
                    musicTitle: dto.musicTitle,
                    likes: dto.likes,
                    comments: dto.comments,
                    shares: dto.shares,
                    userAvatarURL: dto.userAvatarURL,
                    authorId: dto.author_id,
                    latitude: dto.latitude,
                    longitude: dto.longitude,
                    isLocationProtected: dto.is_location_protected ?? false,
                    isLiked: likedVideoIds.contains(dto.id),
                    authorMonetizationEnabled: dto.author?.monetization_enabled ?? false,
                    authorRevenueMultiplier: dto.author?.revenue_multiplier ?? 1
                )
            }
            
            if loadMore {
                self.videos.append(contentsOf: newVideos)
            } else {
                self.videos = newVideos
            }
        } catch {
            print("Error fetching videos: \(error)")
            if !loadMore {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func toggleLike(for videoId: UUID) async {
        guard let index = videos.firstIndex(where: { $0.id == videoId }) else { return }
        let video = videos[index]
        let wasLiked = video.isLiked
        
        // Optimistic UI
        videos[index].isLiked.toggle()
        videos[index].likes += wasLiked ? -1 : 1
        
        do {
            let user = try await client.auth.session.user
            
            if wasLiked {
                // Unlike
                try await client.database
                    .from("likes")
                    .delete()
                    .eq("video_id", value: videoId.uuidString)
                    .eq("user_id", value: user.id.uuidString)
                    .execute()
                
                try? await client.database.rpc("decrement_like_count", params: ["v_id": videoId.uuidString]).execute()
            } else {
                // Like
                try await client.database
                    .from("likes")
                    .insert(["video_id": videoId.uuidString, "user_id": user.id.uuidString])
                    .execute()
                
                try? await client.database.rpc("increment_like_count", params: ["v_id": videoId.uuidString]).execute()
            }
        } catch {
            print("Error toggling like: \(error)")
            // Revert optimistic UI if error
            videos[index].isLiked = wasLiked
            videos[index].likes = video.likes
        }
    }
    
    deinit {
        channel?.unsubscribe()
    }
}
