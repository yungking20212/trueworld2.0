import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppDesignSystem.Components.DynamicBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                searchHeader
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Discover creators")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                } else if viewModel.searchResults.isEmpty {
                    Spacer()
                    Text("No users found")
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.searchResults) { user in
                                NavigationLink(destination: PeerProfileView(viewModel: PeerProfileViewModel(userId: user.id))) {
                                    SearchResultRow(user: user)
                                }
                            }
                        }
                        .padding()
                    }
                }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search users...", text: $viewModel.searchQuery)
                    .foregroundColor(.white)
                    .tint(.pink)
                    .onChange(of: viewModel.searchQuery) { newValue in
                        viewModel.performSearch()
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
        }
        .padding()
        .background(Color.black.opacity(0.4))
    }
}

struct SearchResultRow: View {
    let user: AppUser
    
    var body: some View {
        HStack(spacing: 15) {
            AppAvatar(url: user.avatarURL, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName ?? user.username ?? "Anonymous")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("@\(user.username ?? "user")")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.3))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(12)
        .glassy(cornerRadius: 16)
    }
}

#Preview {
    SearchView()
}
