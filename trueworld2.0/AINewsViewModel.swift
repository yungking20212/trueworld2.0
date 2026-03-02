import Foundation
import Supabase
import Combine

@MainActor
class AINewsViewModel: ObservableObject {
    @Published var newsItems: [AppAINews] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    func fetchNews() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.database
                .from("ai_news")
                .select("*")
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let dtos = try decoder.decode([AppAINews].self, from: response.data)
            self.newsItems = dtos
        } catch {
            print("Error fetching AI news: \(error)")
            // If table doesn't exist, we'll provide some sample data for demonstration
            self.newsItems = getSampleNews()
        }
        
        isLoading = false
    }
    
    private func getSampleNews() -> [AppAINews] {
        return [
            AppAINews(
                id: UUID(),
                title: "AI Predicts: Virtual Cities by 2030",
                content: "Our AI engine analyzes urban development trends and suggests the first fully autonomous virtual twin cities will emerge within this decade, revolutionizing remote work and social interaction.",
                category: "Future Tech",
                isPrediction: true,
                createdAt: Date()
            ),
            AppAINews(
                id: UUID(),
                title: "Celebrity AI clones are the new reality",
                content: "Today's data shows a 300% increase in licensed AI voice and image usage for major A-list stars. Experts predict a shift from physical appearances to digital presence by late next year.",
                category: "Celebrity",
                isPrediction: false,
                createdAt: Date()
            ),
            AppAINews(
                id: UUID(),
                title: "Global energy shift detected",
                content: "Satellite data analysis indicates a major breakthrough in decentralized solar grids in developing nations. AI models suggest energy costs will drop by 40% globally in the next 18 months.",
                category: "World",
                isPrediction: true,
                createdAt: Date().addingTimeInterval(-3600)
            )
        ]
    }
}
