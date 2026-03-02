import SwiftUI
import Supabase
import Combine

class GameCreditManager: ObservableObject {
    static let shared = GameCreditManager()
    
    @Published var balance: Int = 800
    @Published var sessionEarned: Int = 0
    @Published var isSyncing: Bool = false
    @Published var userTier: UserTier = .standard
    
    enum UserTier: String {
        case standard = "STANDARD"
        case premium = "PREMIUM"
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://your-project.supabase.co")!,
        supabaseKey: "your-key"
    )
    
    private init() {
        // Debounced Auto-Sync
        $balance
            .dropFirst()
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.syncWithCloud() }
            }
            .store(in: &cancellables)
    }
    
    func addCredits(_ amount: Int) {
        sessionEarned += amount
        balance += amount
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func useCredits(_ amount: Int) {
        guard balance >= amount else { return }
        balance -= amount
    }
    
    func syncWithCloud() async {
        guard !isSyncing else { return }
        
        await MainActor.run { isSyncing = true }
        
        // Simulate network latency
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        print("Cloud Sync Complete: Balance \(balance)")
        
        await MainActor.run {
            self.sessionEarned = 0
            self.isSyncing = false
        }
    }
}
