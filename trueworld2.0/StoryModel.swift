import Foundation

public struct AppStory: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let mediaURL: URL
    public let mediaType: String // "image" or "video"
    public let createdAt: Date
    public let expiresAt: Date
    public let isLocked: Bool
    public let price: Double
    public let latitude: Double?
    public let longitude: Double?
    public let isLocationProtected: Bool
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case userId = "user_id"
        case mediaURL = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case isLocked = "is_locked"
        case price
        case latitude
        case longitude
        case isLocationProtected = "is_location_protected"
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        mediaURL = try container.decode(URL.self, forKey: .mediaURL)
        mediaType = try container.decode(String.self, forKey: .mediaType)
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        // Handle optional location safely
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        isLocationProtected = try container.decodeIfPresent(Bool.self, forKey: .isLocationProtected) ?? false
        
        // Handle date strings from Supabase (ISO8601)
        let dateStr = try container.decode(String.self, forKey: .createdAt)
        let expiresStr = try container.decode(String.self, forKey: .expiresAt)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateStr) {
            createdAt = date
        } else {
            let fallback = ISO8601DateFormatter()
            createdAt = fallback.date(from: dateStr) ?? Date()
        }
        
        if let date = formatter.date(from: expiresStr) {
            expiresAt = date
        } else {
            let fallback = ISO8601DateFormatter()
            expiresAt = fallback.date(from: expiresStr) ?? Date().addingTimeInterval(86400)
        }
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(mediaURL, forKey: .mediaURL)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(price, forKey: .price)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(isLocationProtected, forKey: .isLocationProtected)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(expiresAt, forKey: .expiresAt)
    }
}

public struct StoryInsert: Encodable, Sendable {
    public let user_id: UUID
    public let media_url: String
    public let media_type: String
    public let is_locked: Bool
    public let price: Double
    public let latitude: Double?
    public let longitude: Double?
    /// Optional: encode only when the column exists in the DB
    public let is_location_protected: Bool?
    public let expires_at: String

    public init(userId: UUID, mediaUrl: String, mediaType: String = "image", isLocked: Bool = false, price: Double = 0.0, latitude: Double? = nil, longitude: Double? = nil, isLocationProtected: Bool? = nil, expiresAt: String) {
        self.user_id = userId
        self.media_url = mediaUrl
        self.media_type = mediaType
        self.is_locked = isLocked
        self.price = price
        self.latitude = latitude
        self.longitude = longitude
        self.is_location_protected = isLocationProtected
        self.expires_at = expiresAt
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(media_url, forKey: .media_url)
        try container.encode(media_type, forKey: .media_type)
        try container.encode(is_locked, forKey: .is_locked)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(is_location_protected, forKey: .is_location_protected)
        try container.encode(expires_at, forKey: .expires_at)
    }

    enum CodingKeys: String, CodingKey {
        case user_id, media_url, media_type, is_locked, price, latitude, longitude, is_location_protected, expires_at
    }
}
