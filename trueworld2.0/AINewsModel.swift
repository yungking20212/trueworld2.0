import Foundation

public struct AppAINews: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let content: String
    public let category: String
    public let isPrediction: Bool
    public let createdAt: Date
    
    public init(id: UUID, title: String, content: String, category: String, isPrediction: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.isPrediction = isPrediction
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case title
        case content
        case category
        case isPrediction = "is_prediction"
        case createdAt = "created_at"
    }
}

public struct AppAINewsDTO: Codable, Sendable {
    public let id: UUID
    public let title: String
    public let content: String
    public let category: String
    public let is_prediction: Bool
    public let created_at: Date
}
