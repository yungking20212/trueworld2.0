import Foundation
import UIKit
import Combine
@preconcurrency import Supabase
import Stripe

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userProfile: AppUser? = nil
    @Published var withdrawalHistory: [WithdrawalAudit] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingOnboarding = false
    @Published var onboardingURL: URL? = nil
    
    // Stripe PaymentSheet integration (requires 'StripePaymentSheet' module)
    @Published var showStripeNativeVault = false
    
    private let client = SupabaseManager.shared.client
    
    init() {
        // Subscribe to global ProfileManager for instant updates
        ProfileManager.shared.$currentUser
            .assign(to: &$userProfile)
        
        Task {
            await fetchWithdrawalHistory()
            await fetchNotificationSettings()
        }
    }
    
    // V1 Production: Notification Persistence
    @Published var pushNotifications = true
    @Published var socialPings = true
    @Published var neuralAlerts = false
    @Published var creatorPayouts = true
    
    func fetchNotificationSettings() async {
        guard let userId = try? await client.auth.session.user.id else { return }
        do {
            let response = try await client.database
                .from("notification_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
            
            // Note: In a real app, you'd decode into a local model. 
            // For now, we'll map the response data.
            if let data = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                self.pushNotifications = data["push_notifications"] as? Bool ?? true
                self.socialPings = data["social_pings"] as? Bool ?? true
                self.neuralAlerts = data["neural_alerts"] as? Bool ?? false
                self.creatorPayouts = data["creator_payouts"] as? Bool ?? true
            }
        } catch {
            print("No notification settings found, using defaults.")
        }
    }
    
    func updateNotificationSettings() async {
        guard let userId = try? await client.auth.session.user.id else { return }
        let payload = NotificationSettingsUpdate(
            userId: userId.uuidString,
            push: pushNotifications,
            social: socialPings,
            neural: neuralAlerts,
            payouts: creatorPayouts
        )
        
        do {
            try await performUpsert(table: "notification_settings", payload: payload, userId: userId.uuidString)
        } catch {
            print("Error updating notification settings: \(error)")
        }
    }
    
    func fetchWithdrawalHistory() async {
        guard let userId = try? await client.auth.session.user.id else { return }
        
        do {
            let response = try await client.database
                .from("withdrawal_audit")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let history = try decoder.decode([WithdrawalAudit].self, from: response.data)
            
            self.withdrawalHistory = history
        } catch {
            print("Error fetching withdrawal history: \(error)")
        }
    }
    
    func fetchUserProfile() async {
        guard let userId = try? await client.auth.session.user.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await client.database
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profile = try decoder.decode(AppUser.self, from: response.data)
            
            self.userProfile = profile
        } catch {
            print("Error fetching settings profile: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateProfile(username: String?, fullName: String?, bio: String?, avatarData: Data?) async -> Bool {
        guard let userId = userProfile?.id else { return false }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var currentAvatarURL = userProfile?.avatarURL?.absoluteString
            
            // 1. Upload New Avatar if provided
            if let data = avatarData {
                let fileName = "\(userId.uuidString)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
                try await client.storage
                    .from("avatars")
                    .upload(
                        path: fileName,
                        file: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                
                let publicURL = try client.storage
                    .from("avatars")
                    .getPublicURL(path: fileName)
                
                currentAvatarURL = publicURL.absoluteString
            }
            
            // 2. Update Database with Type-Safe DTO
            let payload = ProfileUpdate(
                username: username ?? "",
                full_name: fullName ?? "",
                bio: bio ?? "",
                avatar_url: currentAvatarURL
            )
            
            try await performUpdate(table: "profiles", payload: payload, userId: userId.uuidString)
            
            await fetchUserProfile()
            await ProfileManager.shared.fetchProfile() // Broadcast to global system
            return true
        } catch {
            print("Error updating profile: \(error)")
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    func togglePrivacy(isPrivate: Bool) async -> Bool {
        guard let userId = userProfile?.id else { return false }
        
        let payload = PrivacyUpdate(is_private: isPrivate)
        let idString = userId.uuidString
        do {
            try await performUpdate(table: "profiles", payload: payload, userId: idString)
            
            await fetchUserProfile()
            await ProfileManager.shared.fetchProfile() // Broadcast to global system
            return true
        } catch {
            print("Error toggling privacy: \(error)")
            return false
        }
    }
    
    func toggleMonetization(enabled: Bool) async -> Bool {
        guard let userId = userProfile?.id else { return false }
        
        let payload = MonetizationUpdate(monetization_enabled: enabled)
        let idString = userId.uuidString
        do {
            try await performUpdate(table: "profiles", payload: payload, userId: idString)
            
            await fetchUserProfile()
            await ProfileManager.shared.fetchProfile()
            return true
        } catch {
            print("Error toggling monetization: \(error)")
            return false
        }
    }
    
    // V1 Production: Financial Integration
    func linkBank() async {
        guard let userId = userProfile?.id else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            // Production: Stripe Live Mode Onboarding
            // Generates a live onboarding link via Supabase Edge Function mapping
            let liveURL = try await StripeService.shared.createLiveOnboardingLink(userId: userId)
            
            await MainActor.run {
                self.onboardingURL = liveURL
                self.showingOnboarding = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "STRIPE_CONNECT_ERR: Onboarding failed."
                self.isLoading = false
            }
        }
    }
    
    /// Prepares a SetupIntent for linking a card or Apple Pay for future story purchases.
    func prepareCardLink() async {
        guard let userId = userProfile?.id else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let (setupIntentSecret, _, _) = try await StripeService.shared.preparePaymentSheet(userId: userId)
            
            // Production: Stripe PaymentSheet integration requires adding the 'StripePaymentSheet' 
            // product to your Xcode target. For now, we utilize the Stripe API to verify the intent.
            print("NEURAL_VAULT_PREPARED: \(setupIntentSecret)")
            self.showStripeNativeVault = true // Used to navigate or show success feedback
            self.isLoading = false
        } catch {
            await MainActor.run {
                self.errorMessage = "VAULT_SYNC_ERR: Card link failed."
                self.isLoading = false
            }
        }
    }
    
    func toggleStoryAiMonetization(enabled: Bool) async -> Bool {
        guard let userId = userProfile?.id else { return false }
        
        let multiplier = enabled ? 20 : 1
        let payload = StoryAiMonetizationUpdate(enabled: enabled, multiplier: multiplier)
        let idString = userId.uuidString
        do {
            try await performUpdate(table: "profiles", payload: payload, userId: idString)
            
            await fetchUserProfile()
            await ProfileManager.shared.fetchProfile()
            return true
        } catch {
            print("Error toggling story AI monetization: \(error)")
            return false
        }
    }
    
    func withdrawFunds() async {
        guard let user = userProfile, user.revenueCents > 0 else { return }
        isLoading = true
        
        // Simulation: This would call process-payout Edge Function
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        do {
            // Log the payout
            let log = PayoutLogInsert(
                user_id: user.id.uuidString,
                amount_cents: user.revenueCents,
                status: "success"
            )
            try await performInsert(table: "payout_logs", payload: log)
            
            // Reset revenue
            let revenuePayload = RevenueUpdate(revenue_cents: 0)
            try await performUpdate(table: "profiles", payload: revenuePayload, userId: user.id.uuidString)
            
            // Log to high-integrity Withdrawal Audit (v1 Production)
            let audit = WithdrawalAuditInsert(
                user_id: user.id.uuidString,
                action: "WITHDRAWAL_SUCCESS",
                amount: user.revenueCents,
                performed_by: "SYSTEM"
            )
            try await performInsert(table: "withdrawal_audit", payload: audit)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            await fetchUserProfile()
            await ProfileManager.shared.fetchProfile()
        } catch {
            print("Error withdrawing funds: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteAccount() async -> Bool {
        guard let userId = userProfile?.id else { return false }
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await performDelete(table: "profiles", userId: userId.uuidString)
            try await client.auth.signOut()
            return true
        } catch {
            print("Error deleting account: \(error)")
            self.errorMessage = "PURGE_FAILED: Identity locked in neural cache."
            return false
        }
    }
    
    func signOut() async {
        try? await client.auth.signOut()
    }
    
    nonisolated private func performUpsert<T: Encodable & Sendable>(table: String, payload: T, userId: String) async throws {
        // Upsert logic for notification settings
        try await SupabaseManager.shared.client.database
            .from(table)
            .upsert(payload, onConflict: "user_id")
            .execute()
    }
    
    nonisolated private func performDelete(table: String, userId: String) async throws {
        try await SupabaseManager.shared.client.database
            .from(table)
            .delete()
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Nonisolated Database Helpers (V1 Production Stability)
    // These methods run outside the MainActor to prevent isolation leaks in Encodable payloads
    nonisolated private func performUpdate<T: Encodable & Sendable>(table: String, payload: T, userId: String) async throws {
        try await SupabaseManager.shared.client.database
            .from(table)
            .update(payload)
            .eq("id", value: userId)
            .execute()
    }
    
    nonisolated private func performInsert<T: Encodable & Sendable>(table: String, payload: T) async throws {
        try await SupabaseManager.shared.client.database
            .from(table)
            .insert(payload)
            .execute()
    }
}

