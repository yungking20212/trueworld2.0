import Foundation

public nonisolated struct AIScene: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public var videoURL: URL?
    public var status: GenerationStatus
    
    public enum GenerationStatus: String, Codable, Sendable {
        case pending, generating, completed, failed
    }
    
    public init(id: UUID = UUID(), title: String, description: String, videoURL: URL? = nil, status: GenerationStatus = .pending) {
        self.id = id
        self.title = title
        self.description = description
        self.videoURL = videoURL
        self.status = status
    }
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id, title, description, videoURL = "video_url", status
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(status, forKey: .status)
    }
}

public nonisolated struct AIProduction: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let scriptPrompt: String
    public let genre: String
    public var scenes: [AIScene]
    public var castMemberURLs: [URL]
    public let resolution: String
    public let dimension: String
    public let isTunvision: Bool
    public let createdAt: Date
    
    public init(id: UUID = UUID(), userId: UUID, title: String, scriptPrompt: String, genre: String, scenes: [AIScene] = [], castMemberURLs: [URL] = [], resolution: String = "4K", dimension: String = "4D", isTunvision: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.scriptPrompt = scriptPrompt
        self.genre = genre
        self.scenes = scenes
        self.castMemberURLs = castMemberURLs
        self.resolution = resolution
        self.dimension = dimension
        self.isTunvision = isTunvision
        self.createdAt = createdAt
    }
}

// DTO for Supabase
public nonisolated struct AIProductionDTO: Codable, Sendable {
    public let id: UUID
    public let user_id: UUID
    public let title: String
    public let script_prompt: String
    public let genre: String
    public let scenes: [AIScene]
    public let cast_member_urls: [String]
    public let resolution: String
    public let dimension: String
    public let is_tunvision: Bool
    public let created_at: Date
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id, user_id, title, script_prompt, genre, scenes, cast_member_urls, resolution, dimension, is_tunvision, created_at
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(title, forKey: .title)
        try container.encode(script_prompt, forKey: .script_prompt)
        try container.encode(genre, forKey: .genre)
        try container.encode(scenes, forKey: .scenes)
        try container.encode(cast_member_urls, forKey: .cast_member_urls)
        try container.encode(resolution, forKey: .resolution)
        try container.encode(dimension, forKey: .dimension)
        try container.encode(is_tunvision, forKey: .is_tunvision)
        try container.encode(created_at, forKey: .created_at)
    }
}

public nonisolated struct SceneUpdateDTO: Codable, Sendable {
    public let scenes: [AIScene]
    
    public init(scenes: [AIScene]) {
        self.scenes = scenes
    }
    
    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scenes, forKey: .scenes)
    }
    
    enum CodingKeys: String, CodingKey, Sendable {
        case scenes
    }
}
