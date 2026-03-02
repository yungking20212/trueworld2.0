import Foundation
import Supabase
import SwiftUI
import Combine
import Realtime

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: AppUser?
    @Published var userVideos: [AppVideo] = []
    @Published var likedVideos: [AppVideo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUploading = false
    
    @Published var activeStories: [AppStory] = []
    var hasActiveStories: Bool { !activeStories.isEmpty }
    
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    @Published var totalLikes: Int = 0
    
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannel?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to ProfileManager changes for instant UI updates
        ProfileManager.shared.$currentUser
            .sink { [weak self] user in
                self?.userProfile = user
                if let user = user {
                    self?.followersCount = user.followerCount
                    self?.followingCount = user.followingCount
                }
            }
            .store(in: &cancellables)
            
        ProfileManager.shared.$isUploading
            .receive(on: RunLoop.main)
            .assign(to: \.isUploading, on: self)
            .store(in: &cancellables)
    }
    
    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await client.auth.session.user
            setupRealtimeSubscription(userId: user.id)
            
            await ProfileManager.shared.fetchProfile()
            self.userProfile = ProfileManager.shared.currentUser
            
            self.followersCount = self.userProfile?.followerCount ?? 0
            self.followingCount = self.userProfile?.followingCount ?? 0
            
            let decoder = JSONDecoder()
            
            // Fetch user videos from the privacy-masked view
            // Force type for compiler clarity on complex Supabase chains
            let videoResponse: PostgrestResponse = try await client
                .database
                .from("videos")
                .select("*, author:profiles!author_id(username, avatar_url, follower_count)")
                .eq("author_id", value: user.id.uuidString)
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
                    isLocationProtected: dto.is_location_protected ?? false,
                    createdAt: dto.created_at ?? Date()
                )
            }
            
            self.totalLikes = videoDTOs.reduce(0) { $0 + $1.likes }
            
        } catch {
            print("Error fetching profile: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        await fetchLikedVideos()
        await fetchActiveStories()
        isLoading = false
    }
    
    func fetchActiveStories() async {
        guard let userProfile = userProfile else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Explicitly select known columns to avoid schema cache errors when optional columns are missing.
            let response = try await client.database
                .from("stories")
                .select("id, user_id, media_url, media_type, created_at, expires_at, is_locked, price, latitude, longitude")
                .eq("user_id", value: userProfile.id.uuidString)
                .gte("expires_at", value: ISO8601DateFormatter().string(from: Date()))
                .execute()

            self.activeStories = try decoder.decode([AppStory].self, from: response.data)
        } catch {
            print("Error fetching active stories: \(error)")
        }
    }
    
    private func setupRealtimeSubscription(userId: UUID) {
        guard channel == nil else { return }
        
        let channel = client.realtime.channel("public:follows:profile")
        self.channel = channel
        
        channel.on("postgres_changes", filter: ChannelFilter(event: "*", schema: "public", table: "follows")) { [weak self] message in
            Task { @MainActor [weak self] in
                // Real-time follow change detected
                await self?.fetchProfile()
            }
        }
        
        channel.subscribe()
    }
    
    func fetchLikedVideos() async {
        do {
            let user = try await client.auth.session.user
            
            let response = try await client
                .database
                .from("likes")
                .select("video:videos(*, author:profiles!author_id(username, avatar_url, follower_count))")
                .eq("user_id", value: user.id)
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
                    isLocationProtected: dto.is_location_protected ?? false,
                    isLiked: true,
                    createdAt: dto.created_at ?? Date()
                )
            }
        } catch {
            print("Error fetching liked videos: \(error)")
        }
    }
    
    deinit {
        channel?.unsubscribe()
    }
}
