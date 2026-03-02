import Foundation
import Supabase
import SwiftUI
import Combine
import Realtime

@MainActor
class PeerProfileViewModel: ObservableObject {
    @Published var userProfile: AppUser?
    @Published var userVideos: [AppVideo] = []
    @Published var likedVideos: [AppVideo] = []
    @Published var isLoading = false
    @Published var isCurrentUser = false
    @Published var isFollowing = false
    @Published var errorMessage: String?
    
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var totalLikes: Int = 0
    
    private let userId: UUID
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannel?
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            setupRealtimeSubscription()
            
            // 1. Fetch profile data
            let profileResponse = try await client
                .database
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let profileDTO = try decoder.decode(AppProfileDTO.self, from: profileResponse.data)
            
            // 2. Fetch live neural XP for peer profile
            let xpResponse = try? await client
                .database
                .from("profile_levels")
                .select("xp")
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            var realXP = profileDTO.xp ?? 0
            if let xpData = xpResponse?.data,
               let xpDict = try? JSONDecoder().decode([String: Int].self, from: xpData) {
                realXP = xpDict["xp"] ?? 0
            }
            
            self.userProfile = AppUser(
                id: profileDTO.id,
                username: profileDTO.username,
                fullName: profileDTO.fullName,
                avatarURL: profileDTO.avatarURL,
                bio: profileDTO.bio,
                isPrivate: profileDTO.isPrivate,
                followerCount: profileDTO.followerCount,
                followingCount: profileDTO.followingCount,
                xp: realXP,
                monetizationEnabled: profileDTO.monetization_enabled ?? false,
                revenueCents: profileDTO.revenue_cents ?? 0
            )
            
            self.followersCount = profileDTO.followerCount
            self.followingCount = profileDTO.followingCount
            
            // 2. Fetch user videos from the privacy-masked view
            let videoResponse: PostgrestResponse = try await client
                .database
                .from("videos")
                .select("*, author:profiles!author_id(username, avatar_url, follower_count)")
                .eq("author_id", value: userId.uuidString)
                .execute()
            
            let videoDTOs = try decoder.decode([GlobalVideoMetadata].self, from: videoResponse.data)
            
            self.userVideos = videoDTOs.map { dto in
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
                    isLocationProtected: dto.is_location_protected ?? false
                )
            }
            
            self.totalLikes = videoDTOs.reduce(0) { $0 + $1.likes }
            
            // 3. Check follow status
            if let currentUser = try? await client.auth.session.user {
                self.isCurrentUser = currentUser.id == userId
                
                if !isCurrentUser {
                    let followResponse = try await client.database
                        .from("follows")
                        .select()
                        .eq("follower_id", value: currentUser.id)
                        .eq("following_id", value: userId)
                        .execute()
                    
                    self.isFollowing = !followResponse.data.isEmpty && followResponse.data != "[]".data(using: .utf8)
                }
            }
            
            // 4. Fetch liked videos
            await fetchLikedVideos()
            
        } catch {
            print("Error fetching peer profile: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func setupRealtimeSubscription() {
        guard channel == nil else { return }
        
        let channel = client.realtime.channel("public:follows:peer:\(userId.uuidString)")
        self.channel = channel
        
        channel.on("postgres_changes", filter: ChannelFilter(event: "*", schema: "public", table: "follows")) { [weak self] message in
            Task { @MainActor [weak self] in
                // Real-time follow change detected
                await self?.fetchProfile()
            }
        }
        
        channel.subscribe()
    }
    
    func toggleFollow() async {
        do {
            let currentUser = try await client.auth.session.user
            
            if isFollowing {
                try await client.database
                    .from("follows")
                    .delete()
                    .eq("follower_id", value: currentUser.id)
                    .eq("following_id", value: userId)
                    .execute()
                isFollowing = false
            } else {
                try await client.database
                    .from("follows")
                    .insert([
                        "follower_id": currentUser.id.uuidString,
                        "following_id": userId.uuidString
                    ])
                    .execute()
                isFollowing = true
            }
            // Counts will be updated via Realtime
        } catch {
            print("Error toggling follow: \(error)")
        }
    }
    
    func fetchLikedVideos() async {
        do {
            let response: PostgrestResponse = try await client
                .database
                .from("likes")
                .select("video:videos(*, author:profiles!author_id(username, avatar_url, follower_count))")
                .eq("user_id", value: userId)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct LikedVideoWrapper: Codable {
                let video: GlobalVideoMetadata
            }
            
            let wrappedDTOs = try decoder.decode([LikedVideoWrapper].self, from: response.data)
            let videoDTOs = wrappedDTOs.map { $0.video }
            
            self.likedVideos = videoDTOs.map { dto in
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
                    isLiked: true
                )
            }
        } catch {
            print("Error fetching peer liked videos: \(error)")
        }
    }
    
    deinit {
        channel?.unsubscribe()
    }
}
