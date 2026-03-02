import Foundation
import Supabase
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [AppUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    private var searchTask: Task<Void, Never>?
    
    func performSearch() {
        // Cancel previous task to debounce
        searchTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Ignore if cancelled
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                guard !Task.isCancelled else { return }
                
                let response = try await client
                    .database
                    .from("profiles")
                    .select()
                    .ilike("username", value: "%\(searchQuery)%")
                    .execute()
                
                let decoder = JSONDecoder()
                let fetchedDTOs = try decoder.decode([AppProfileDTO].self, from: response.data)
                
                guard !Task.isCancelled else { return }
                
                self.searchResults = fetchedDTOs.map { dto in
                    AppUser(
                        id: dto.id,
                        username: dto.username,
                        fullName: dto.fullName ?? "",
                        avatarURL: dto.avatarURL,
                        bio: dto.bio
                    )
                }
            } catch {
                if !Task.isCancelled {
                    print("Search error: \(error)")
                    self.errorMessage = "Failed to search users"
                    self.searchResults = []
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
}
