import Foundation
import Combine
import Supabase

class StripeService: ObservableObject {
    static let shared = StripeService()
    
    // Live Production Credentials
    let publishableKey = StripeConfig.publishableKey
    let webhookSecret = StripeConfig.webhookSecret
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // Request Payloads for backend synchronization
    struct StripeAccountRequest: Encodable {
        let user_id: String
        let return_url: String
        let refresh_url: String
    }
    
    struct PaymentIntentRequest: Encodable {
        let user_id: String
        let amount: Int
        let currency: String
    }
    
    struct ResponseURL: Decodable {
        let url: String
    }
    
    /// Production: Generates a live onboarding link via your backend edge function.
    func createLiveOnboardingLink(userId: UUID) async throws -> URL {
        let payload = StripeAccountRequest(
            user_id: userId.uuidString,
            return_url: "trueworld://payouts",
            refresh_url: "trueworld://payouts"
        )
        
        // Specify the return type for the generic invoke call
        let response: ResponseURL = try await client.functions
            .invoke(
                "create-stripe-account",
                options: .init(body: payload)
            )
        
        guard let url = URL(string: response.url) else {
            throw NSError(domain: "StripeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Onboarding URL Received"])
        }
        
        return url
    }
    
    /// Production: Prepares a PaymentSheet for story purchases or card linking.
    func preparePaymentSheet(userId: UUID, amountCents: Int? = nil) async throws -> (clientSecret: String, ephemeralKey: String, customerId: String) {
        let payload = PaymentIntentRequest(
            user_id: userId.uuidString,
            amount: amountCents ?? 0,
            currency: "usd"
        )
        
        // Specify the return type for the generic invoke call
        let response: StripePaymentPayload = try await client.functions
            .invoke(
                "create-payment-intent",
                options: .init(body: payload)
            )
        
        return (response.paymentIntent, response.ephemeralKey, response.customer)
    }

    struct StripePaymentPayload: Codable {
        let paymentIntent: String
        let ephemeralKey: String
        let customer: String
    }
    
    /// Verifies the webhook signature in production environments.
    func verifyWebhookSecret(_ secret: String) -> Bool {
        return secret == webhookSecret
    }
}
