import Foundation

public struct AppNotification: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let actorId: UUID
    public let actor: ProfileAvatarDTO?
    public let type: String // "like", "comment", "follow", "mention", "message", "repost", "neural_ping"
    public let postId: UUID?
    public let commentId: UUID?
    public let messageId: UUID?
    public var isRead: Bool
    public let createdAt: Date
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case actor
        case type
        case postId = "post_id"
        case commentId = "comment_id"
        case messageId = "message_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        actorId = try container.decode(UUID.self, forKey: .actorId)
        actor = try container.decodeIfPresent(ProfileAvatarDTO.self, forKey: .actor)
        type = try container.decode(String.self, forKey: .type)
        postId = try container.decodeIfPresent(UUID.self, forKey: .postId)
        commentId = try container.decodeIfPresent(UUID.self, forKey: .commentId)
        messageId = try container.decodeIfPresent(UUID.self, forKey: .messageId)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        
        // Handle various date formats including fractional seconds
        let dateStr = try container.decode(String.self, forKey: .createdAt)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateStr) {
            createdAt = date
        } else {
            let fallbackFormatter = ISO8601DateFormatter()
            if let date = fallbackFormatter.date(from: dateStr) {
                createdAt = date
            } else {
                createdAt = Date() // Fallback
            }
        }
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(actorId, forKey: .actorId)
        try container.encode(actor, forKey: .actor)
        try container.encode(type, forKey: .type)
        try container.encode(postId, forKey: .postId)
        try container.encode(commentId, forKey: .commentId)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(isRead, forKey: .isRead)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
