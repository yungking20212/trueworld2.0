import Foundation
import Combine
import AVFoundation

class SpaceNoiseManager: ObservableObject {
    static let shared = SpaceNoiseManager()
    
    private var player: AVAudioPlayer?
    private var isPlaying = false
    
    private init() {
        // Initializing the player from the bundle
        setupPlayer()
    }
    
    private func setupPlayer() {
        // Updated to use specific Alien Whispers orbital audio
        guard let url = Bundle.main.url(forResource: "fnx_sound-alien-whispers-in-space-287357", withExtension: "mp3") else {
            print("SPACE_NOISE: Source missing (fnx_sound-alien-whispers-in-space-287357.mp3).")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // Infinite loop
            player?.volume = 0 // Start silent
            player?.prepareToPlay()
        } catch {
            print("SPACE_NOISE: Failed to init player: \(error)")
        }
    }
    
    func updateSpaceAmbient(zoomLevel: Double) {
        // zoomLevel = latitudeDelta (0 to 180)
        // We start playing noise when zoomLevel > 50
        let threshold: Double = 50.0
        let maxZoom: Double = 160.0
        
        if zoomLevel > threshold {
            if !isPlaying {
                player?.play()
                isPlaying = true
                print("SPACE_NOISE: Entering orbital acoustics...")
            }
            
            // Map zoomLevel (50-160) to volume (0.0-0.7)
            let progress = (zoomLevel - threshold) / (maxZoom - threshold)
            let volume = min(0.7, max(0.0, Float(progress) * 0.7))
            
            player?.setVolume(volume, fadeDuration: 0.5)
        } else if isPlaying {
            // Zoomed in, fade out
            player?.setVolume(0, fadeDuration: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !self.isPlaying { return } // Already handled
                self.player?.pause()
                self.isPlaying = false
                print("SPACE_NOISE: Returning to terrestrial frequency.")
            }
        }
    }
}
