import Foundation
import Supabase
import SwiftUI
import PhotosUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var username = ""
    @Published var fullName = ""
    @Published var bio = ""
    @Published var selectedItem: PhotosPickerItem?
    @Published var avatarData: Data?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isComplete = false
    
    private let client = SupabaseManager.shared.client
    
    func saveProfile() async {
        guard !username.isEmpty else {
            errorMessage = "Username is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await client.auth.session.user
            var avatarURL: String? = nil
            
            // 1. Upload Avatar if selected
            if let data = avatarData {
                let fileName = "\(user.id.uuidString)/avatar.jpg"
                try await client.storage
                    .from("avatars")
                    .upload(
                        path: fileName,
                        file: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                
                let publicURL = try client.storage
                    .from("avatars")
                    .getPublicURL(path: fileName)
                
                avatarURL = publicURL.absoluteString
            }
            
            // 2. Update Profile
            var updates: [String: String] = [
                "id": user.id.uuidString,
                "username": username,
                "full_name": fullName,
                "bio": bio
            ]
            
            if let avatarURL = avatarURL {
                updates["avatar_url"] = avatarURL
            }
            
            try await client.database
                .from("profiles")
                .upsert(updates)
                .execute()
            
            isComplete = true
        } catch {
            print("Onboarding error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func handleImageSelection() async {
        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
            avatarData = data
        }
    }
}
