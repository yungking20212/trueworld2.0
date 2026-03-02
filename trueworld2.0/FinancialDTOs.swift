import Foundation

// MARK: - Database Payloads (Sendable DTOs)
// These must stay decoupled from the @MainActor to satisfy Sendable requirements for PostgREST
public struct MonetizationUpdate: Encodable, Sendable { 
    public let monetization_enabled: Bool 
    public init(monetization_enabled: Bool) { self.monetization_enabled = monetization_enabled }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(monetization_enabled, forKey: .monetization_enabled)
    }
    
    enum CodingKeys: String, CodingKey {
        case monetization_enabled
    }
}
public struct RevenueUpdate: Encodable, Sendable { 
    public let revenue_cents: Int 
    public init(revenue_cents: Int) { self.revenue_cents = revenue_cents }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(revenue_cents, forKey: .revenue_cents)
    }
    
    enum CodingKeys: String, CodingKey {
        case revenue_cents
    }
}

public struct PayoutLogInsert: Encodable, Sendable {
    public let user_id: String
    public let amount_cents: Int
    public let status: String
    public init(user_id: String, amount_cents: Int, status: String) {
        self.user_id = user_id
        self.amount_cents = amount_cents
        self.status = status
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(amount_cents, forKey: .amount_cents)
        try container.encode(status, forKey: .status)
    }
    
    enum CodingKeys: String, CodingKey {
        case user_id, amount_cents, status
    }
}

public struct WithdrawalAuditInsert: Encodable, Sendable {
    public let user_id: String
    public let action: String
    public let amount: Int
    public let performed_by: String
    public init(user_id: String, action: String, amount: Int, performed_by: String) {
        self.user_id = user_id
        self.action = action
        self.amount = amount
        self.performed_by = performed_by
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(action, forKey: .action)
        try container.encode(amount, forKey: .amount)
        try container.encode(performed_by, forKey: .performed_by)
    }
    
    enum CodingKeys: String, CodingKey {
        case user_id, action, amount, performed_by
    }
}

public struct PrivacyUpdate: Encodable, Sendable {
    public let is_private: Bool
    public init(is_private: Bool) { self.is_private = is_private }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(is_private, forKey: .is_private)
    }
    
    enum CodingKeys: String, CodingKey {
        case is_private
    }
}

public struct BankLinkUpdate: Encodable, Sendable {
    public let stripe_account_id: String
    public let payout_status: String
    public let bank_last4: String?
    public let bank_name: String?
    
    public init(accountId: String, status: String, last4: String?, name: String?) {
        self.stripe_account_id = accountId
        self.payout_status = status
        self.bank_last4 = last4
        self.bank_name = name
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stripe_account_id, forKey: .stripe_account_id)
        try container.encode(payout_status, forKey: .payout_status)
        try container.encode(bank_last4, forKey: .bank_last4)
        try container.encode(bank_name, forKey: .bank_name)
    }
    
    enum CodingKeys: String, CodingKey {
        case stripe_account_id, payout_status, bank_last4, bank_name
    }
}

public struct ProfileUpdate: Encodable, Sendable {
    public let username: String
    public let full_name: String
    public let bio: String
    public let avatar_url: String?
    public init(username: String, full_name: String, bio: String, avatar_url: String?) {
        self.username = username
        self.full_name = full_name
        self.bio = bio
        self.avatar_url = avatar_url
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(full_name, forKey: .full_name)
        try container.encode(bio, forKey: .bio)
        try container.encode(avatar_url, forKey: .avatar_url)
    }
    
    enum CodingKeys: String, CodingKey {
        case username, full_name, bio, avatar_url
    }
}

public struct ReportInsert: Encodable, Sendable {
    public let user_id: String
    public let message: String
    public let category: String
    public let status: String
    
    public init(user_id: String, message: String, category: String = "general", status: String = "pending") {
        self.user_id = user_id
        self.message = message
        self.category = category
        self.status = status
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(message, forKey: .message)
        try container.encode(category, forKey: .category)
        try container.encode(status, forKey: .status)
    }
    
    enum CodingKeys: String, CodingKey {
        case user_id, message, category, status
    }
}

public struct NotificationSettingsUpdate: Encodable, Sendable {
    public let user_id: String
    public let push_notifications: Bool
    public let social_pings: Bool
    public let neural_alerts: Bool
    public let creator_payouts: Bool
    
    public init(userId: String, push: Bool, social: Bool, neural: Bool, payouts: Bool) {
        self.user_id = userId
        self.push_notifications = push
        self.social_pings = social
        self.neural_alerts = neural
        self.creator_payouts = payouts
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(push_notifications, forKey: .push_notifications)
        try container.encode(social_pings, forKey: .social_pings)
        try container.encode(neural_alerts, forKey: .neural_alerts)
        try container.encode(creator_payouts, forKey: .creator_payouts)
    }
    
    enum CodingKeys: String, CodingKey {
        case user_id, push_notifications, social_pings, neural_alerts, creator_payouts
    }
}

public struct StoryAiMonetizationUpdate: Encodable, Sendable {
    public let story_ai_monetization_enabled: Bool
    public let revenue_multiplier: Int
    
    public init(enabled: Bool, multiplier: Int) {
        self.story_ai_monetization_enabled = enabled
        self.revenue_multiplier = multiplier
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(story_ai_monetization_enabled, forKey: .story_ai_monetization_enabled)
        try container.encode(revenue_multiplier, forKey: .revenue_multiplier)
    }
    
    enum CodingKeys: String, CodingKey {
        case story_ai_monetization_enabled, revenue_multiplier
    }
}
