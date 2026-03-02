import Foundation

public struct WithdrawalAudit: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID?
    public let action: String // "WITHDRAWAL_REQUEST", "WITHDRAWAL_SUCCESS", "WITHDRAWAL_FAILED"
    public let amount: Int // in cents
    public let performedBy: String?
    public let createdAt: Date
    
    enum CodingKeys: String, CodingKey, Sendable {
        case id
        case userId = "user_id"
        case action
        case amount
        case performedBy = "performed_by"
        case createdAt = "created_at"
    }
    
    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        action = try container.decode(String.self, forKey: .action)
        amount = try container.decode(Int.self, forKey: .amount)
        performedBy = try container.decodeIfPresent(String.self, forKey: .performedBy)
        
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
}
