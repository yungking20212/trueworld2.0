import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let videoURL: URL
    let isPlaying: Bool
    var scale: CGFloat = 1.0
    
    func makeCoordinator() -> Coordinator {
        Coordinator(videoURL: videoURL)
    }
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(frame: .zero)
        view.playerLayer.player = context.coordinator.player
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        // Handle URL changes
        if context.coordinator.videoURL != videoURL {
            context.coordinator.updateURL(videoURL)
        }
        
        // Handle Play/Pause
        if isPlaying {
            context.coordinator.player.play()
        } else {
            context.coordinator.player.pause()
        }
    }
    
    static func dismantleUIView(_ uiView: PlayerUIView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
    
    class Coordinator: NSObject {
        var videoURL: URL
        let player: AVPlayer
        
        init(videoURL: URL) {
            self.videoURL = videoURL
            self.player = AVPlayer(url: videoURL)
            super.init()
            
            player.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidReachEnd(notification:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
        }
        
        @objc func playerItemDidReachEnd(notification: Notification) {
            player.seek(to: .zero)
            player.play()
        }
        
        func updateURL(_ newURL: URL) {
            self.videoURL = newURL
            let item = AVPlayerItem(url: newURL)
            player.replaceCurrentItem(with: item)
        }
        
        func cleanup() {
            player.pause()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

class PlayerUIView: UIView {
    var playerLayer = AVPlayerLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
