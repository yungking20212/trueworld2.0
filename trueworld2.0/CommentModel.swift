import Foundation

public struct AppComment: Identifiable, Codable, Sendable {
    public let id: UUID
    public let videoId: UUID
    public let userId: UUID
    public let username: String
    public let userAvatarURL: URL?
    public let followerCount: Int
    public let content: String
    public var likes: Int
    public let parentId: UUID?
    public let editedAt: Date?
    public let createdAt: Date
    
    public init(id: UUID, videoId: UUID, userId: UUID, username: String, userAvatarURL: URL?, followerCount: Int = 0, content: String, likes: Int = 0, parentId: UUID? = nil, editedAt: Date? = nil, createdAt: Date) {
        self.id = id
        self.videoId = videoId
        self.userId = userId
        self.username = username
        self.userAvatarURL = userAvatarURL
        self.followerCount = followerCount
        self.content = content
        self.likes = likes
        self.parentId = parentId
        self.editedAt = editedAt
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case videoId = "video_id"
        case userId = "user_id"
        case username
        case userAvatarURL = "user_avatar_url"
        case followerCount = "follower_count"
        case content = "body"
        case likes
        case parentId = "parent_id"
        case editedAt = "edited_at"
        case createdAt = "created_at"
    }
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        videoId = try container.decode(UUID.self, forKey: .videoId)
        userId = try container.decode(UUID.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        userAvatarURL = try container.decodeIfPresent(URL.self, forKey: .userAvatarURL)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        content = try container.decode(String.self, forKey: .content)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)

        // Dates may come as ISO8601 strings or as Date objects depending on decoder
        if let createdDate = try? container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = createdDate
        } else if let createdStr = try? container.decodeIfPresent(String.self, forKey: .createdAt) {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = iso.date(from: createdStr) ?? Date()
        } else {
            createdAt = Date()
        }

        if let editedDate = try? container.decodeIfPresent(Date.self, forKey: .editedAt) {
            editedAt = editedDate
        } else if let editedStr = try? container.decodeIfPresent(String.self, forKey: .editedAt) {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            editedAt = editedStr != nil ? iso.date(from: editedStr) : nil
        } else {
            editedAt = nil
        }
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(videoId, forKey: .videoId)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(userAvatarURL, forKey: .userAvatarURL)
        try container.encode(followerCount, forKey: .followerCount)
        try container.encode(content, forKey: .content)
        try container.encode(likes, forKey: .likes)
        try container.encode(parentId, forKey: .parentId)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(iso.string(from: createdAt), forKey: .createdAt)

        if let edited = editedAt {
            try container.encode(iso.string(from: edited), forKey: .editedAt)
        }
    }
}

public struct AppCommentDTO: Codable, Sendable {
    public let id: UUID
    public let videoId: UUID
    public let userId: UUID
    public let content: String
    public let likes: Int?
    public let parentId: UUID?
    public let editedAt: Date?
    public let createdAt: Date
    public let author: ProfileAvatarDTO?
    
    enum CodingKeys: String, CodingKey {
        case id
        case videoId = "video_id"
        case userId = "user_id"
        case content = "body"
        case likes
        case parentId = "parent_id"
        case editedAt = "edited_at"
        case createdAt = "created_at"
        case author
    }
    
    public var username: String? { author?.username }
    public var avatarURL: String? { author?.avatarURL?.absoluteString }
    public var followerCount: Int { author?.followerCount ?? 0 }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        videoId = try container.decode(UUID.self, forKey: .videoId)
        userId = try container.decode(UUID.self, forKey: .userId)
        content = try container.decode(String.self, forKey: .content)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        // createdAt may be provided as an ISO8601 string or a Date value
        if let createdDate = try? container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = createdDate
        } else if let dateStr = try? container.decodeIfPresent(String.self, forKey: .createdAt) {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = iso.date(from: dateStr) ?? Date()
        } else {
            createdAt = Date()
        }

        if let editedDate = try? container.decodeIfPresent(Date.self, forKey: .editedAt) {
            editedAt = editedDate
        } else if let editedDateStr = try? container.decodeIfPresent(String.self, forKey: .editedAt) {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            editedAt = editedDateStr != nil ? iso.date(from: editedDateStr) : nil
        } else {
            editedAt = nil
        }
        
        author = try container.decodeIfPresent(ProfileAvatarDTO.self, forKey: .author)
    }
}

extension AppCommentDTO {
    /// Convert DTO to `AppComment` using `author` metadata when available.
    public func toAppComment() -> AppComment {
        return AppComment(
            id: id,
            videoId: videoId,
            userId: userId,
            username: author?.username ?? "",
            userAvatarURL: author?.avatarURL,
            followerCount: author?.followerCount ?? 0,
            content: content,
            likes: likes ?? 0,
            parentId: parentId,
            editedAt: editedAt,
            createdAt: createdAt
        )
    }
}
