import Foundation
import Supabase
import SwiftUI
import PhotosUI
import Combine

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var username = ""
    @Published var fullName = ""
    @Published var bio = ""
    @Published var avatarURL: URL?
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var avatarData: Data?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let client = SupabaseManager.shared.client
    
    init(user: AppUser) {
        self.username = user.username ?? ""
        self.fullName = user.fullName ?? ""
        self.bio = user.bio ?? ""
        self.avatarURL = user.avatarURL
    }
    
    func updateProfile() async {
        isLoading = true
        errorMessage = nil
        isSuccess = false
        
        do {
            let user = try await client.auth.session.user
            var currentAvatarURL = avatarURL?.absoluteString
            
            // 1. Upload New Avatar if selected
            if let data = avatarData {
                let fileName = "\(user.id.uuidString)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
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
                
                currentAvatarURL = publicURL.absoluteString
            }
            
            // 2. Update Database with Type-Safe DTO
            let payload = ProfileUpdate(
                username: username,
                full_name: fullName,
                bio: bio,
                avatar_url: currentAvatarURL
            )
            
            try await performUpdate(payload: payload, userId: user.id.uuidString)
            
            // 3. Update Global Profile Manager for instant synchronization across all views
            await ProfileManager.shared.fetchProfile()
            
            isSuccess = true
        } catch {
            print("Update profile error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Nonisolated Helper (Prevent isolation leaks)
    nonisolated private func performUpdate(payload: ProfileUpdate, userId: String) async throws {
        try await SupabaseManager.shared.client.database
            .from("profiles")
            .update(payload)
            .eq("id", value: userId)
            .execute()
    }
    
    func handleImageSelection() async {
        if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
            avatarData = data
        }
    }
}
