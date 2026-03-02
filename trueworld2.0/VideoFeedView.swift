import Supabase
import SwiftUI

struct VideoFeedView: View {
    @StateObject private var viewModel = VideoFeedViewModel()
    @State private var activeVideoID: UUID?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.videos.isEmpty {
                    VStack(spacing: 20) {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(AppDesignSystem.Colors.primaryGradient, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(360))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: true)
                        
                        Text("Discovering...")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else if viewModel.videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No videos found")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Button(action: { 
                            Task {
                                await viewModel.fetchVideos()
                            }
                        }) {
                            Text("Try Again")
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .glassy(cornerRadius: 25)
                        }
                        .foregroundColor(.white)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.videos) { video in
                                VideoItemView(
                                    video: video,
                                    viewModel: viewModel,
                                    proxy: proxy,
                                    isPlaying: activeVideoID == video.id
                                )
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .id(video.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $activeVideoID)
                    .scrollTargetBehavior(.paging)
                    .scrollBounceBehavior(.basedOnSize)
                    .ignoresSafeArea(.all)
                    .onChange(of: viewModel.videos.first?.id) { _, firstId in
                        if activeVideoID == nil {
                            activeVideoID = firstId
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .onAppear {
                if viewModel.videos.isEmpty {
                    Task { await viewModel.fetchVideos() }
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

struct VideoItemView: View {
    let video: AppVideo
    @ObservedObject var viewModel: VideoFeedViewModel
    let proxy: GeometryProxy
    let isPlaying: Bool
    
    @State private var showHeartPop = false
    @State private var heartOffset: CGPoint = .zero
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VideoPlayerView(videoURL: video.videoURL, isPlaying: isPlaying)
                .ignoresSafeArea()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .onTapGesture(count: 2) { location in
                    heartOffset = location
                    showHeartPop = true
                    Task {
                        if !video.isLiked {
                            await viewModel.toggleLike(for: video.id)
                        }
                    }
                }
            
            if showHeartPop {
                HeartPopView(isPresented: $showHeartPop)
                    .position(heartOffset)
            }
            
            VideoOverlayView(video: video, onLike: {
                Task {
                    await viewModel.toggleLike(for: video.id)
                }
            })
            
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
        .clipped()
        .onAppear {
            // Trigger preloading when near the end (e.g., when the last video appears)
            if let lastId = viewModel.videos.last?.id, lastId == video.id {
                Task {
                    await viewModel.fetchVideos(loadMore: true)
                }
            }
        }
    }
}

struct HeartPopView: View {
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 100))
            .foregroundColor(.red)
            .shadow(color: .black.opacity(0.3), radius: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        scale = 1.5
                        opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    isPresented = false
                }
            }
    }
}

#Preview {
    VideoFeedView()
}
