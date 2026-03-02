import SwiftUI

struct VideoGridView: View {
    let videos: [AppVideo]
    let emptyMessage: String
    var onVideoTap: ((AppVideo) -> Void)? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        if videos.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.2))
                
                Text(emptyMessage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
            .background(.ultraThinMaterial.opacity(0.1))
            .cornerRadius(20)
            .padding(.horizontal, 24)
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(videos) { video in
                    ZStack(alignment: .bottomLeading) {
                        // Secure the 3:4 ratio container
                        Color.black.opacity(0.1)
                            .aspectRatio(3/4, contentMode: .fill)
                            .overlay(
                                VideoThumbnailView(url: video.videoURL)
                            )
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onVideoTap?(video)
                            }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text(formatCount(video.likes))
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .allowsHitTesting(false)
                    }
                }
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }
}
