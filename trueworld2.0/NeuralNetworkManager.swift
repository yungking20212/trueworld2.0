import Foundation
import Supabase
import Realtime
import Combine

/// High-performance orchestration layer for real-time social broadcasting.
/// Optimized for "Neural Pings" and "Global Scans" bypassing database hits for transient data.
class NeuralNetworkManager: ObservableObject {
    static let shared = NeuralNetworkManager()
    
    private let client = SupabaseManager.shared.client
    private var globalChannel: RealtimeChannel?
    
    @Published var activeScanners: Int = 0
    @Published var latestWorldPulse: String = "IDLE"
    
    private init() {
        setupGlobalChannel()
    }
    
    private func setupGlobalChannel() {
        let channel = client.realtime.channel("neural_broadcast")
        self.globalChannel = channel
        
        // Listen for transient "Neural Pings"
        channel.on("broadcast", filter: ChannelFilter(event: "ping")) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleIncomingPing()
            }
        }
        
        // Listen for "Neural Scans" (Presence)
        channel.on("presence", filter: ChannelFilter(event: "sync")) { [weak self] _ in
            self?.syncPresence()
        }
        
        channel.subscribe()
    }
    
    private func handleIncomingPing() {
        // High-concurrency ping processing
        self.latestWorldPulse = "PULSE_DETECTED"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.latestWorldPulse = "STABLE"
        }
    }
    
    private func syncPresence() {
        guard let channel = globalChannel else { return }
        // Note: Realtime SDK version might vary, using a safe approach to get presence count
        let presenceCount = channel.presenceState().count
        DispatchQueue.main.async {
            self.activeScanners = presenceCount
        }
    }
    
    /// Sends a low-latency "Neural Ping" to all active users on the map.
    /// This bypasses the database for maximum performance.
    func sendNeuralPing(type: String, data: [String: Any]) async {
        guard let channel = globalChannel else { return }
        
        do {
            try await channel.send(
                type: .broadcast, event: "ping",
                payload: [
                    "type": type,
                    "timestamp": ISO8601DateFormatter().string(from: Date()),
                    "payload": data
                ]
            )
        } catch {
            print("Neural Broadcast Error: \(error)")
        }
    }
    
    /// Joins the "Neural Map" presence group.
    func joinNeuralMap(user: AppUser) async {
        guard let channel = globalChannel else { return }
        // Simple track for simulation or use metadata if SDK supports
        try? await channel.track(["user_id": user.id.uuidString])
    }
    
    func leaveNeuralMap() async {
        try? await globalChannel?.untrack()
    }
}
