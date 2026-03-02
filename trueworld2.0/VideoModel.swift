import Foundation

public struct AppVideo: Identifiable, Codable, Sendable {
    public let id: UUID
    public let videoURL: URL
    public let username: String
    public let description: String
    public let musicTitle: String
    public var likes: Int
    public let comments: Int
    public let shares: Int
    public var viewsCount: Int
    public let userAvatarURL: URL?
    public let authorId: UUID
    public let latitude: Double?
    public let longitude: Double?
    public let isLocationProtected: Bool
    public let createdAt: Date
    public var isLiked: Bool = false
    public var globalRank: Int?
    public var neuralScore: Int?
    public var authorMonetizationEnabled: Bool = false
    public var authorRevenueMultiplier: Int = 1
    
    public init(id: UUID, videoURL: URL, username: String, description: String, musicTitle: String, likes: Int, comments: Int, shares: Int, viewsCount: Int = 0, userAvatarURL: URL?, authorId: UUID, latitude: Double? = nil, longitude: Double? = nil, isLocationProtected: Bool = false, isLiked: Bool = false, globalRank: Int? = nil, neuralScore: Int? = nil, authorMonetizationEnabled: Bool = false, authorRevenueMultiplier: Int = 1, createdAt: Date = Date()) {
        self.id = id
        self.videoURL = videoURL
        self.username = username
        self.description = description
        self.musicTitle = musicTitle
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.viewsCount = viewsCount
        self.userAvatarURL = userAvatarURL
        self.authorId = authorId
        self.latitude = latitude
        self.longitude = longitude
        self.isLocationProtected = isLocationProtected
        self.isLiked = isLiked
        self.globalRank = globalRank
        self.neuralScore = neuralScore
        self.authorMonetizationEnabled = authorMonetizationEnabled
        self.authorRevenueMultiplier = authorRevenueMultiplier
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case videoURL = "video_url"
        case username
        case description
        case musicTitle = "music_title"
        case likes
        case comments
        case shares
        case viewsCount = "views_count"
        case userAvatarURL = "user_avatar_url"
        case authorId = "author_id"
        case latitude
        case longitude
        case isLocationProtected = "is_location_protected"
        case globalRank = "global_rank"
        case neuralScore = "neural_score"
        case createdAt = "created_at"
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? "Unknown User"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        musicTitle = try container.decodeIfPresent(String.self, forKey: .musicTitle) ?? "Original Sound"
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        comments = try container.decodeIfPresent(Int.self, forKey: .comments) ?? 0
        shares = try container.decodeIfPresent(Int.self, forKey: .shares) ?? 0
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount) ?? 0
        userAvatarURL = try container.decodeIfPresent(URL.self, forKey: .userAvatarURL)
        authorId = try container.decode(UUID.self, forKey: .authorId)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        isLocationProtected = (try? container.decode(Bool.self, forKey: .isLocationProtected)) ?? false
        isLiked = false // Default
        globalRank = try container.decodeIfPresent(Int.self, forKey: .globalRank)
        neuralScore = try container.decodeIfPresent(Int.self, forKey: .neuralScore)
        
        let dateStr = (try? container.decode(String.self, forKey: .createdAt)) ?? ""
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        createdAt = formatter.date(from: dateStr) ?? Date()
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(username, forKey: .username)
        try container.encode(description, forKey: .description)
        try container.encode(musicTitle, forKey: .musicTitle)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(shares, forKey: .shares)
        try container.encode(userAvatarURL, forKey: .userAvatarURL)
        try container.encode(authorId, forKey: .authorId)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(isLocationProtected, forKey: .isLocationProtected)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

public struct GlobalVideoMetadata: Codable, Sendable {
    public let id: UUID
    public let videoURL: URL
    public let username: String
    public let description: String
    public let musicTitle: String
    public let likes: Int
    public let comments: Int
    public let shares: Int
    public let views_count: Int?
    public let author: ProfileAvatarDTO?
    public let author_id: UUID
    public let latitude: Double?
    public let longitude: Double?
    public let is_location_protected: Bool?
    public let global_rank: Int?
    public let neural_score: Int?
    public let created_at: Date?
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case videoURL = "video_url"
        case username
        case description
        case musicTitle = "music_title"
        case likes
        case comments
        case shares
        case views_count
        case author
        case author_id
        case latitude
        case longitude
        case is_location_protected
        case global_rank
        case neural_score
        case created_at
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? "Unknown User"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        musicTitle = try container.decodeIfPresent(String.self, forKey: .musicTitle) ?? "Original Sound"
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        comments = try container.decodeIfPresent(Int.self, forKey: .comments) ?? 0
        shares = try container.decodeIfPresent(Int.self, forKey: .shares) ?? 0
        views_count = try container.decodeIfPresent(Int.self, forKey: .views_count)
        author = try container.decodeIfPresent(ProfileAvatarDTO.self, forKey: .author)
        author_id = try container.decode(UUID.self, forKey: .author_id)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        is_location_protected = try container.decodeIfPresent(Bool.self, forKey: .is_location_protected)
        global_rank = try container.decodeIfPresent(Int.self, forKey: .global_rank)
        neural_score = try container.decodeIfPresent(Int.self, forKey: .neural_score)
        
        if let dateStr = try? container.decode(String.self, forKey: .created_at) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            created_at = formatter.date(from: dateStr)
        } else {
            created_at = nil
        }
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(username, forKey: .username)
        try container.encode(description, forKey: .description)
        try container.encode(musicTitle, forKey: .musicTitle)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(shares, forKey: .shares)
        try container.encode(author, forKey: .author)
        try container.encode(author_id, forKey: .author_id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(is_location_protected, forKey: .is_location_protected)
    }
    
    public var userAvatarURL: URL? {
        author?.avatarURL
    }
}

public struct ProfileAvatarDTO: Codable, Sendable {
    public let username: String?
    public let avatarURL: URL?
    public let followerCount: Int?
    public let monetization_enabled: Bool?
    public let revenue_multiplier: Int?
    
    enum CodingKeys: String, CodingKey, Sendable {
        case username
        case avatarURL = "avatar_url"
        case followerCount = "follower_count"
        case monetization_enabled
        case revenue_multiplier
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount)
        monetization_enabled = try container.decodeIfPresent(Bool.self, forKey: .monetization_enabled)
        revenue_multiplier = try container.decodeIfPresent(Int.self, forKey: .revenue_multiplier)
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(avatarURL, forKey: .avatarURL)
        try container.encode(followerCount, forKey: .followerCount)
    }
}

public struct VideoInsertDTO: Codable, Sendable {
    public let video_url: String
    public let username: String
    public let description: String
    public let music_title: String
    public let likes: Int
    public let comments: Int
    public let shares: Int
    public let author_id: UUID
    public let latitude: Double?
    public let longitude: Double?
    public let is_location_protected: Bool

    public init(video_url: String, username: String, description: String, music_title: String, likes: Int, comments: Int, shares: Int, author_id: UUID, latitude: Double?, longitude: Double?, is_location_protected: Bool) {
        self.video_url = video_url
        self.username = username
        self.description = description
        self.music_title = music_title
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.author_id = author_id
        self.latitude = latitude
        self.longitude = longitude
        self.is_location_protected = is_location_protected
    }

    enum CodingKeys: String, CodingKey {
        case video_url, username, description, music_title, likes, comments, shares, author_id, latitude, longitude, is_location_protected
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(video_url, forKey: .video_url)
        try container.encode(username, forKey: .username)
        try container.encode(description, forKey: .description)
        try container.encode(music_title, forKey: .music_title)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(shares, forKey: .shares)
        try container.encode(author_id, forKey: .author_id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(is_location_protected, forKey: .is_location_protected)
    }

    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        video_url = try container.decode(String.self, forKey: .video_url)
        username = try container.decode(String.self, forKey: .username)
        description = try container.decode(String.self, forKey: .description)
        music_title = try container.decode(String.self, forKey: .music_title)
        likes = try container.decode(Int.self, forKey: .likes)
        comments = try container.decode(Int.self, forKey: .comments)
        shares = try container.decode(Int.self, forKey: .shares)
        author_id = try container.decode(UUID.self, forKey: .author_id)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        is_location_protected = try container.decode(Bool.self, forKey: .is_location_protected)
    }
}
