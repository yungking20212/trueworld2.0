import Combine
import Supabase
import SwiftUI

@MainActor
class InboxViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = SupabaseManager.shared.client
            let userId = try await client.auth.session.user.id
            
            // For now, we fetch from a 'conversations' view or table
            // In a real app, this would be a custom Postgres function or complex query
            let response = try await client
                .database
                .from("conversations")
                .select()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let fetched = try decoder.decode([Conversation].self, from: response.data)
            self.conversations = fetched
        } catch {
            // Ignore cancellations (e.g., task cancelled by SwiftUI on refresh/navigation)
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                // Don't treat as an error to show the user
                return
            }

            print("Error fetching conversations: \(error)")
            // If the table doesn't exist yet (PGRST205), show a helpful message
            let errString = "\(error)"
            if errString.contains("PGRST205") {
                self.errorMessage = "Messenger is being synchronized. Please check back later!"
            } else {
                self.errorMessage = error.localizedDescription
            }
            self.conversations = []
        }
        
        isLoading = false
    }
}
