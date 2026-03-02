import Foundation
import Supabase
import SwiftUI
import Combine
internal import _Helpers

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUp = false
    
    func signIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Pass username in the `data` parameter so the auth endpoint receives metadata
            // required by DB triggers that create profiles (username must be non-null).
            var metadata: [String: AnyJSON]? = nil
            if !username.isEmpty {
                metadata = ["username": .string(username)]
            }
            try await SupabaseManager.shared.client.auth.signUp(email: email, password: password, data: metadata)
            isSignUp = false // Switch back to sign in after successful sign up
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
