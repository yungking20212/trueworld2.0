import SwiftUI
import AVKit
import Combine

struct StoryViewer: View {
    let stories: [AppStory]
    @Binding var isPresented: Bool
    @State private var currentIndex = 0
    @State private var progress: Double = 0.0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !stories.isEmpty {
                let story = stories[currentIndex]
                
                StoryMediaView(story: story, isActive: true)
                    .id(story.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                
                // Story Overlays
                VStack {
                    // Progress Bars
                    HStack(spacing: 4) {
                        ForEach(0..<stories.count, id: \.self) { index in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                
                                if index == currentIndex {
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: progress * 100, height: 3) // Simplified width calculation
                                } else if index < currentIndex {
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(height: 3)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                
                // Navigation gestures
                HStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            previousStory()
                        }
                    
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nextStory()
                        }
                }
            }
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
                Spacer()
            }
        }
        .onReceive(timer) { _ in
            updateProgress()
        }
    }
    
    private func nextStory() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            progress = 0
        } else {
            isPresented = false
        }
    }
    
    private func previousStory() {
        if currentIndex > 0 {
            currentIndex -= 1
            progress = 0
        }
    }
    
    private func updateProgress() {
        progress += 0.02 // Adjust for 5-second stories
        if progress >= 1.0 {
            nextStory()
        }
    }
}

// v3 Story Media Engine
struct StoryMediaView: View {
    let story: AppStory
    let isActive: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if story.isLocked {
                lockedView
            } else if story.mediaType == "video" {
                videoView
            } else {
                imageView
            }
        }
        .onAppear {
            if story.mediaType == "video" {
                setupPlayer()
            }
        }
        .onDisappear {
            player?.pause()
        }
        .onChange(of: isActive) { active in
            if active {
                player?.seek(to: .zero)
                player?.play()
            } else {
                player?.pause()
            }
        }
    }
    
    private var videoView: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        if isActive { player.play() }
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
    }
    
    private var imageView: some View {
        AsyncImage(url: story.mediaURL) { phase in
            switch phase {
            case .empty:
                ProgressView().tint(.white)
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.white.opacity(0.3))
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private var lockedView: some View {
        ZStack {
            // Blurred Background
            if story.mediaType == "video" {
                Color.black // Simplified for locked blur
            } else {
                AsyncImage(url: story.mediaURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill).blur(radius: 40)
                } placeholder: { Color.black }
            }
            
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(story.mediaType == "video" ? "PRIVATE BROADCAST" : "LOCKED PING")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Button(action: {
                    // Purchase handled externally in production
                }) {
                    Text("UNLOCK $\(story.price, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppDesignSystem.Colors.primaryGradient)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func setupPlayer() {
        let player = AVPlayer(url: story.mediaURL)
        player.preventsDisplaySleepDuringVideoPlayback = true
        self.player = player
        if isActive {
            player.play()
        }
    }
}
