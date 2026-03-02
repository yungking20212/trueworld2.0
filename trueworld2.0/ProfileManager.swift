import Foundation
import Supabase
import SwiftUI
import Combine

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var isUploading = false
    
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannel?
    
    private init() {
        listenToAuthState()
        Task {
            // Initial fetch if already logged in
            if (try? await client.auth.session) != nil {
                await fetchProfile()
            }
        }
    }
    
    func fetchProfile() async {
        guard let user = try? await client.auth.session.user else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let profileResponse = try await client
                .database
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let profileDTO = try decoder.decode(AppProfileDTO.self, from: profileResponse.data)
            
            // Separate fetch for real-time neural XP from the profile_levels view
            let xpResponse = try? await client
                .database
                .from("profile_levels")
                .select("xp")
                .eq("user_id", value: user.id)
                .single()
                .execute()
            
            var realXP = profileDTO.xp ?? 0
            if let xpData = xpResponse?.data,
               let xpDict = try? JSONDecoder().decode([String: Int].self, from: xpData) {
                realXP = xpDict["xp"] ?? 0
            }
            
            self.currentUser = AppUser(
                id: profileDTO.id,
                username: profileDTO.username,
                fullName: profileDTO.fullName,
                avatarURL: profileDTO.avatarURL,
                bio: profileDTO.bio,
                isPrivate: profileDTO.isPrivate,
                followerCount: profileDTO.followerCount,
                followingCount: profileDTO.followingCount,
                xp: realXP,
                monetizationEnabled: profileDTO.monetization_enabled ?? false,
                revenueCents: profileDTO.revenue_cents ?? 0,
                storyAiMonetizationEnabled: profileDTO.story_ai_monetization_enabled ?? false,
                revenueMultiplier: profileDTO.revenue_multiplier ?? 1,
                stripeAccountId: profileDTO.stripe_account_id,
                payoutStatus: profileDTO.payout_status,
                bankLast4: profileDTO.bank_last4,
                bankName: profileDTO.bank_name,
                momentumScore: profileDTO.momentum_score,
                isRisingStar: profileDTO.is_rising_star,
                cityName: profileDTO.city_name,
                dailyRank: profileDTO.daily_rank
            )
        } catch {
            print("Error fetching profile in ProfileManager: \(error)")
        }
    }
    
    private func setupRealtimeSubscription(userId: UUID) {
        // Unsubscribe from any existing channel first
        channel?.unsubscribe()
        channel = nil
        
        let channel = client.realtime.channel("public:profile_updates:\(userId.uuidString)")
        self.channel = channel
        
        // Listen for profile metadata changes
        channel.on("postgres_changes", filter: ChannelFilter(event: "UPDATE", schema: "public", table: "profiles", filter: "id=eq.\(userId.uuidString)")) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchProfile()
            }
        }
        
        // Listen for XP/Level changes specifically
        channel.on("postgres_changes", filter: ChannelFilter(event: "*", schema: "public", table: "profile_levels", filter: "user_id=eq.\(userId.uuidString)")) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchProfile()
            }
        }
        
        channel.subscribe()
    }
    
    private func listenToAuthState() {
        // Create a long-running listener for auth changes
        Task {
            for await (event, session) in await client.auth.authStateChanges {
                await MainActor.run {
                    if event == .signedIn, let user = session?.user {
                        Task {
                            await self.fetchProfile()
                            self.setupRealtimeSubscription(userId: user.id)
                        }
                    } else if event == .signedOut {
                        self.currentUser = nil
                        self.channel?.unsubscribe()
                        self.channel = nil
                    }
                }
            }
        }
    }
    
    func updateLocalProfile(_ user: AppUser) {
        self.currentUser = user
    }
}
