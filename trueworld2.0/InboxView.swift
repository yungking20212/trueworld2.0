import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppDesignSystem.Components.DynamicBackground()
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 50)
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No messages yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Button(action: {}) {
                            Text("Start a conversation")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppDesignSystem.Colors.primaryGradient)
                                .cornerRadius(20)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.top, 100)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(viewModel.conversations) { conversation in
                                NavigationLink(destination: ChatView(conversation: conversation)) {
                                    ConversationRow(conversation: conversation)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Messenger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchConversations()
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 14) {
            AppAvatar(url: conversation.otherUserAvatarURL, size: 56)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName ?? "User")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Text(conversation.lastMessage ?? "No messages yet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: conversation.updatedAt, relativeTo: Date())
    }
}

#Preview {
    InboxView()
}
