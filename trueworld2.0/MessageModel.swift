import Foundation

struct AppMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let content: String
    let createdAt: Date
    let senderName: String?
    let senderAvatarURL: URL?
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case content
        case createdAt = "created_at"
        case senderName = "sender_name"
        case senderAvatarURL = "sender_avatar_url"
    }
    
    init(id: UUID, senderId: UUID, receiverId: UUID, content: String, createdAt: Date, senderName: String? = nil, senderAvatarURL: URL? = nil) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.createdAt = createdAt
        self.senderName = senderName
        self.senderAvatarURL = senderAvatarURL
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        senderId = try container.decode(UUID.self, forKey: .senderId)
        receiverId = try container.decode(UUID.self, forKey: .receiverId)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        senderName = try container.decodeIfPresent(String.self, forKey: .senderName)
        senderAvatarURL = try container.decodeIfPresent(URL.self, forKey: .senderAvatarURL)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(senderAvatarURL, forKey: .senderAvatarURL)
    }
}

struct Conversation: Identifiable, Codable, Sendable {
    let id: UUID
    let otherUserId: UUID
    let otherUserName: String?
    let otherUserAvatarURL: URL?
    let lastMessage: String?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case otherUserId = "other_user_id"
        case otherUserName = "other_user_name"
        case otherUserAvatarURL = "other_user_avatar_url"
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, otherUserId: UUID, otherUserName: String? = nil, otherUserAvatarURL: URL? = nil, lastMessage: String? = nil, updatedAt: Date) {
        self.id = id
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.otherUserAvatarURL = otherUserAvatarURL
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        otherUserId = try container.decode(UUID.self, forKey: .otherUserId)
        otherUserName = try container.decodeIfPresent(String.self, forKey: .otherUserName)
        otherUserAvatarURL = try container.decodeIfPresent(URL.self, forKey: .otherUserAvatarURL)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(otherUserId, forKey: .otherUserId)
        try container.encode(otherUserName, forKey: .otherUserName)
        try container.encode(otherUserAvatarURL, forKey: .otherUserAvatarURL)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
