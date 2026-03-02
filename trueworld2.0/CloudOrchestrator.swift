import SwiftUI
import Combine

enum InstanceState: String {
    case idle = "IDLE"
    case k8sAllocation = "K8S_ALLOCATING_NODE..."
    case pullingImage = "DOCKER_PULLING_IMAGE..."
    case gpuAttachment = "ATTACHING_GPU_VRAM..."
    case booting = "PROVISIONING_CONTAINER..."
    case streaming = "LIVE_STREAMING"
    case error = "BACKEND_ERROR"
}

class CloudOrchestrator: ObservableObject {
    static let shared = CloudOrchestrator()
    
    @Published var currentState: InstanceState = .idle
    @Published var activeGPUType: String = "NVIDIA L40 (48GB GDDR6)"
    @Published var region: String = "US-EAST-1 (AWS g6.xlarge)"
    @Published var sessionDuration: TimeInterval = 0
    @Published var creditsBurned: Int = 0
    @Published var bitrate: Double = 0.0
    @Published var latency: Int = 0
    @Published var fps: Int = 0
    
    private var telemetryTimer: AnyCancellable?
    private var sessionTimer: AnyCancellable?
    
    let gpus = [
        "NVIDIA A10 Tensor Core (24GB)",
        "NVIDIA A100 (80GB VRAM)",
        "NVIDIA L40 (48GB GDDR6)",
        "NVIDIA H100 (Accelerated)"
    ]
    
    func launchSession(for gameId: UUID) {
        let tier = GameCreditManager.shared.userTier
        let waitMultiplier: Double = tier == .premium ? 0.5 : 1.0 // 50% faster for Premium
        
        Task {
            // 1. K8s Allocation
            await MainActor.run { currentState = .k8sAllocation }
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * waitMultiplier))
            
            // 2. Docker Pull
            await MainActor.run { currentState = .pullingImage }
            try? await Task.sleep(nanoseconds: UInt64(1_200_000_000 * waitMultiplier))
            
            // 3. GPU Attachment
            await MainActor.run { 
                currentState = .gpuAttachment
                activeGPUType = gpus.randomElement() ?? "NVIDIA L40"
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // 4. Booting
            await MainActor.run { currentState = .booting }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // 5. Streaming
            await MainActor.run { 
                currentState = .streaming
                CloudStreamingManager.shared.setupPeerConnection()
                startTelemetry()
                startBilling()
            }
        }
    }
    
    private func startTelemetry() {
        telemetryTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.bitrate = Double.random(in: 18.2...24.8)
                self?.latency = Int.random(in: 20...32)
                self?.fps = Int.random(in: 59...61)
            }
    }
    
    private func startBilling() {
        sessionDuration = 0
        creditsBurned = 0
        sessionTimer = Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sessionDuration += 60
                self?.creditsBurned += 10 // 10 credits per minute (user model)
                GameCreditManager.shared.useCredits(10)
            }
    }
    
    func terminateSession() {
        telemetryTimer?.cancel()
        sessionTimer?.cancel()
        telemetryTimer = nil
        sessionTimer = nil
        currentState = .idle
        bitrate = 0.0
        latency = 0
        fps = 0
        sessionDuration = 0
        creditsBurned = 0
    }
}
