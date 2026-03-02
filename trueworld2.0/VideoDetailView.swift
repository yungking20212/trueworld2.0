import SwiftUI
import Combine
import Supabase
import PostgREST
import Realtime

struct VideoDetailView: View {
    let videoId: UUID
    @StateObject private var viewModel = VideoDetailViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let video = viewModel.video {
                    VideoPlayerView(videoURL: video.videoURL, isPlaying: true)
                        .ignoresSafeArea()
                    
                    // Overlay
                    VideoOverlayView(video: video, onLike: {
                        Task { await viewModel.toggleLike() }
                    })
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack {
                        Text("Video not found")
                            .foregroundColor(.white.opacity(0.5))
                        Button("Close") { dismiss() }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                // Close Button
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        .padding(.leading, 20)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchVideo(id: videoId)
            }
        }
    }
}

@MainActor
class VideoDetailViewModel: ObservableObject {
    
    @Published var video: AppVideo?
    @Published var isLoading = false
    
    private let client = SupabaseManager.shared.client
    
    func fetchVideo(id: UUID) async {
        isLoading = true
        do {
            let response = try await client.database
                .from("videos")
                .select("*, author:profiles!author_id(username, avatar_url, follower_count)")
                .eq("id", value: id)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let dto = try decoder.decode(GlobalVideoMetadata.self, from: response.data)
            
            // Check current user likes
            let currentUser = try? await client.auth.session.user
            var isLiked = false
            
            if let userId = currentUser?.id {
                let likesResponse = try await client
                    .database
                    .from("likes")
                    .select("video_id")
                    .eq("video_id", value: id)
                    .eq("user_id", value: userId)
                    .execute()
                
                let decoder = JSONDecoder()
                let likesData = (try? decoder.decode([[String: UUID]].self, from: likesResponse.data)) ?? []
                isLiked = !likesData.isEmpty
            }
            
            self.video = AppVideo(
                id: dto.id,
                videoURL: dto.videoURL,
                username: dto.username,
                description: dto.description,
                musicTitle: dto.musicTitle,
                likes: dto.likes,
                comments: dto.comments,
                shares: dto.shares,
                viewsCount: dto.views_count ?? 0,
                userAvatarURL: dto.userAvatarURL,
                authorId: dto.author_id,
                latitude: dto.latitude,
                longitude: dto.longitude,
                isLocationProtected: dto.is_location_protected ?? false,
                isLiked: isLiked,
                globalRank: dto.global_rank,
                neuralScore: dto.neural_score,
                authorMonetizationEnabled: dto.author?.monetization_enabled ?? false,
                authorRevenueMultiplier: dto.author?.revenue_multiplier ?? 1
            )
            
            // Hardware-level view registration for XP accumulator
            try? await client.database.rpc("register_video_view", params: ["video_id": id.uuidString]).execute()
            
        } catch {
            print("Detail Fetch Error: \(error)")
        }
        isLoading = false
    }
    
    func toggleLike() async {
        guard let currentVideo = video else { return }
        let videoId = currentVideo.id
        let wasLiked = currentVideo.isLiked
        
        // Optimistic UI
        self.video?.isLiked.toggle()
        self.video?.likes += (self.video?.isLiked == true) ? 1 : -1
        
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
            // Revert optimistic UI if failed
            self.video?.isLiked = ((video?.isLiked) != nil)
            self.video?.likes = video!.likes
        }
    }
}
