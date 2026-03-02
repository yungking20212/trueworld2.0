import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage? = nil
    @State private var isLoading = false
    
    // Simple in-memory cache for the session
    static let cache = NSCache<NSURL, UIImage>()
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if isLoading {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                } else {
                    Image(systemName: "video.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 24))
                }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        if let cached = VideoThumbnailView.cache.object(forKey: url as NSURL) {
            self.thumbnail = cached
            return
        }
        
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            let asset = AVAsset(url: url)
            
            do {
                // Ensure the tracks are loaded before generating image
                let _ = try await asset.load(.tracks)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 400, height: 400)
                
                // Use 0.1s as a safer point to avoid initial black frames
                let time = CMTime(seconds: 0.1, preferredTimescale: 600)
                
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                
                VideoThumbnailView.cache.setObject(image, forKey: url as NSURL)
                
                await MainActor.run {
                    self.thumbnail = image
                    self.isLoading = false
                }
            } catch {
                print("Error generating thumbnail for \(url): \(error)")
                
                // Final fallback: try to generate at time 0 if 0.1 fails, or just stop
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
