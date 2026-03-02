import Foundation

public struct AppUser: Identifiable, Codable, Sendable {
    public let id: UUID
    public let username: String?
    public let fullName: String?
    public let avatarURL: URL?
    public let bio: String?
    public let isPrivate: Bool?
    
    public let followerCount: Int
    public let followingCount: Int
    
    public var xp: Int = 0
    public var monetizationEnabled: Bool = false
    public var revenueCents: Int = 0
    public var storyAiMonetizationEnabled: Bool = false
    public var revenueMultiplier: Int = 1
    public var stripeAccountId: String?
    public var payoutStatus: String? // "unlinked", "onboarding", "active"
    public var bankLast4: String?
    public var bankName: String?
    
    // v3 Competitive Features
    public var momentumScore: Double?
    public var isRisingStar: Bool?
    public var cityName: String?
    public var dailyRank: Int?
    
    public var level: Int {
        Int(floor(sqrt(Double(xp) / 25.0)))
    }
    
    public var xpProgress: Double {
        let currentLevel = level
        let nextLevelXP = Double((currentLevel + 1) * (currentLevel + 1) * 25)
        let currentLevelXP = Double(currentLevel * currentLevel * 25)
        let progress = (Double(xp) - currentLevelXP) / (nextLevelXP - currentLevelXP)
        return max(0, min(1, progress))
    }
    
    public var isVerified: Bool {
        followerCount >= 50
    }
    
    public init(id: UUID, username: String?, fullName: String?, avatarURL: URL?, bio: String?, isPrivate: Bool? = false, followerCount: Int = 0, followingCount: Int = 0, xp: Int = 0, monetizationEnabled: Bool = false, revenueCents: Int = 0, storyAiMonetizationEnabled: Bool = false, revenueMultiplier: Int = 1, stripeAccountId: String? = nil, payoutStatus: String? = "unlinked", bankLast4: String? = nil, bankName: String? = nil, momentumScore: Double? = nil, isRisingStar: Bool? = false, cityName: String? = nil, dailyRank: Int? = nil) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.bio = bio
        self.isPrivate = isPrivate
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.xp = xp
        self.monetizationEnabled = monetizationEnabled
        self.revenueCents = revenueCents
        self.storyAiMonetizationEnabled = storyAiMonetizationEnabled
        self.revenueMultiplier = revenueMultiplier
        self.stripeAccountId = stripeAccountId
        self.payoutStatus = payoutStatus
        self.bankLast4 = bankLast4
        self.bankName = bankName
        self.momentumScore = momentumScore
        self.isRisingStar = isRisingStar
        self.cityName = cityName
        self.dailyRank = dailyRank
    }
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case bio
        case isPrivate = "is_private"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case xp
        case monetizationEnabled = "monetization_enabled"
        case revenueCents = "revenue_cents"
        case storyAiMonetizationEnabled = "story_ai_monetization_enabled"
        case revenueMultiplier = "revenue_multiplier"
        case stripeAccountId = "stripe_account_id"
        case payoutStatus = "payout_status"
        case bankLast4 = "bank_last4"
        case bankName = "bank_name"
        case momentumScore = "momentum_score"
        case isRisingStar = "is_rising_star"
        case cityName = "city_name"
        case dailyRank = "daily_rank"
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        monetizationEnabled = try container.decodeIfPresent(Bool.self, forKey: .monetizationEnabled) ?? false
        revenueCents = try container.decodeIfPresent(Int.self, forKey: .revenueCents) ?? 0
        storyAiMonetizationEnabled = try container.decodeIfPresent(Bool.self, forKey: .storyAiMonetizationEnabled) ?? false
        revenueMultiplier = try container.decodeIfPresent(Int.self, forKey: .revenueMultiplier) ?? 1
        stripeAccountId = try container.decodeIfPresent(String.self, forKey: .stripeAccountId)
        payoutStatus = try container.decodeIfPresent(String.self, forKey: .payoutStatus)
        bankLast4 = try container.decodeIfPresent(String.self, forKey: .bankLast4)
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName)
        momentumScore = try container.decodeIfPresent(Double.self, forKey: .momentumScore)
        isRisingStar = try container.decodeIfPresent(Bool.self, forKey: .isRisingStar)
        cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        dailyRank = try container.decodeIfPresent(Int.self, forKey: .dailyRank)
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(avatarURL, forKey: .avatarURL)
        try container.encode(bio, forKey: .bio)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(followerCount, forKey: .followerCount)
        try container.encode(followingCount, forKey: .followingCount)
        try container.encode(xp, forKey: .xp)
        try container.encode(monetizationEnabled, forKey: .monetizationEnabled)
        try container.encode(revenueCents, forKey: .revenueCents)
        try container.encode(storyAiMonetizationEnabled, forKey: .storyAiMonetizationEnabled)
        try container.encode(revenueMultiplier, forKey: .revenueMultiplier)
        try container.encode(stripeAccountId, forKey: .stripeAccountId)
        try container.encode(payoutStatus, forKey: .payoutStatus)
        try container.encode(bankLast4, forKey: .bankLast4)
        try container.encode(bankName, forKey: .bankName)
        try container.encode(momentumScore, forKey: .momentumScore)
        try container.encode(isRisingStar, forKey: .isRisingStar)
        try container.encode(cityName, forKey: .cityName)
        try container.encode(dailyRank, forKey: .dailyRank)
    }
}

public struct AppProfileDTO: Codable, Sendable {
    public let id: UUID
    public let username: String
    public let fullName: String?
    public let avatarURL: URL?
    public let bio: String?
    public let isPrivate: Bool?
    public let followerCount: Int
    public let followingCount: Int
    public let xp: Int?
    public let monetization_enabled: Bool?
    public let revenue_cents: Int?
    public let story_ai_monetization_enabled: Bool?
    public let revenue_multiplier: Int?
    public let stripe_account_id: String?
    public let payout_status: String?
    public let bank_last4: String?
    public let bank_name: String?
    public let momentum_score: Double?
    public let is_rising_star: Bool?
    public let city_name: String?
    public let daily_rank: Int?
    
    public var isVerified: Bool {
        followerCount >= 50
    }

    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case bio
        case isPrivate = "is_private"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case xp
        case monetization_enabled
        case revenue_cents
        case story_ai_monetization_enabled
        case revenue_multiplier
        case stripe_account_id
        case payout_status
        case bank_last4
        case bank_name
        case momentum_score
        case is_rising_star
        case city_name
        case daily_rank
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        xp = try container.decodeIfPresent(Int.self, forKey: .xp)
        monetization_enabled = try container.decodeIfPresent(Bool.self, forKey: .monetization_enabled)
        revenue_cents = try container.decodeIfPresent(Int.self, forKey: .revenue_cents)
        story_ai_monetization_enabled = try container.decodeIfPresent(Bool.self, forKey: .story_ai_monetization_enabled)
        revenue_multiplier = try container.decodeIfPresent(Int.self, forKey: .revenue_multiplier)
        stripe_account_id = try container.decodeIfPresent(String.self, forKey: .stripe_account_id)
        payout_status = try container.decodeIfPresent(String.self, forKey: .payout_status)
        bank_last4 = try container.decodeIfPresent(String.self, forKey: .bank_last4)
        bank_name = try container.decodeIfPresent(String.self, forKey: .bank_name)
        momentum_score = try container.decodeIfPresent(Double.self, forKey: .momentum_score)
        is_rising_star = try container.decodeIfPresent(Bool.self, forKey: .is_rising_star)
        city_name = try container.decodeIfPresent(String.self, forKey: .city_name)
        daily_rank = try container.decodeIfPresent(Int.self, forKey: .daily_rank)
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(avatarURL, forKey: .avatarURL)
        try container.encode(bio, forKey: .bio)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(followerCount, forKey: .followerCount)
        try container.encode(followingCount, forKey: .followingCount)
        try container.encode(xp, forKey: .xp)
        try container.encode(monetization_enabled, forKey: .monetization_enabled)
        try container.encode(revenue_cents, forKey: .revenue_cents)
        try container.encode(story_ai_monetization_enabled, forKey: .story_ai_monetization_enabled)
        try container.encode(revenue_multiplier, forKey: .revenue_multiplier)
        try container.encode(stripe_account_id, forKey: .stripe_account_id)
        try container.encode(payout_status, forKey: .payout_status)
        try container.encode(bank_last4, forKey: .bank_last4)
        try container.encode(bank_name, forKey: .bank_name)
        try container.encode(momentum_score, forKey: .momentum_score)
        try container.encode(is_rising_star, forKey: .is_rising_star)
        try container.encode(city_name, forKey: .city_name)
        try container.encode(daily_rank, forKey: .daily_rank)
    }
}

struct Follow: Codable, Sendable {
    let id: Int
    let followerId: UUID
    let followingId: UUID
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
    }
}
