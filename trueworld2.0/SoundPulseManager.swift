import Foundation
import AVFoundation
import Combine

class SoundPulseManager: ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    
    static let shared = SoundPulseManager()
    
    private var audioEngine: AVAudioEngine
    private var oscillator: AVAudioUnitSampler
    private var noiseGenerator: AVAudioUnitSampler
    private var reverb: AVAudioUnitReverb
    
    @Published var enginePitch: Float = 0.5
    @Published var engineVolume: Float = 0.0
    
    private init() {
        self.objectWillChange = ObservableObjectPublisher()
        audioEngine = AVAudioEngine()
        oscillator = AVAudioUnitSampler()
        noiseGenerator = AVAudioUnitSampler()
        reverb = AVAudioUnitReverb()
        
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 30
        
        audioEngine.attach(oscillator)
        audioEngine.attach(noiseGenerator)
        audioEngine.attach(reverb)
        
        audioEngine.connect(oscillator, to: reverb, format: nil)
        audioEngine.connect(noiseGenerator, to: reverb, format: nil)
        audioEngine.connect(reverb, to: audioEngine.mainMixerNode, format: nil)
        
        try? audioEngine.start()
    }
    
    func startEngine() {
        // In a real app, we'd load a sample. For now, we simulate with MIDI-like notes
        // This is a placeholder for a more complex engine synthesis
        oscillator.startNote(40, withVelocity: 64, onChannel: 0)
    }
    
    func updateEngine(speed: Float, throttle: Float) {
        // Map speed to pitch (0.5 to 2.0)
        let pitch = 0.5 + (speed / 10.0) * 1.5
        enginePitch = pitch
        
        // Map throttle to volume
        let volume = 0.1 + (throttle * 0.4) + (speed / 10.0) * 0.3
        engineVolume = volume
        
        audioEngine.mainMixerNode.outputVolume = volume
    }
    
    func playGlitch() {
        // Placeholder for a digital glitch sound
        noiseGenerator.startNote(100, withVelocity: 127, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.noiseGenerator.stopNote(100, onChannel: 0)
        }
    }
    
    func stopEngine() {
        oscillator.stopNote(40, onChannel: 0)
    }
}
