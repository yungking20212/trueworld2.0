import SwiftUI
import Supabase
import Combine

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @Namespace private var scrollNamespace
    
    init(conversation: Conversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        ZStack {
            // Grounding base (Deep Dark)
            Color.black.ignoresSafeArea()
            
            AppDesignSystem.Colors.overlayBottomGradient
                .opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Glassmorphic & Edge-to-Edge)
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 64) // Finalized Notch/Island height
                    
                    HStack(spacing: 15) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        AppAvatar(url: conversation.otherUserAvatarURL, size: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conversation.otherUserName ?? "User")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Active now")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Button(action: {}) {
                                Image(systemName: "video.fill")
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
                .zIndex(10)
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, isCurrentUser: message.senderId == viewModel.currentUserId)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 140) // Clearance for floating input
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Input Area (Finalized Spacing)
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        TextField("", text: $messageText, prompt: Text("Message...").foregroundColor(.white.opacity(0.4)))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                            .tint(AppDesignSystem.Colors.vibrantPink)
                        
                        Button(action: {
                            if !messageText.isEmpty {
                                Task {
                                    await viewModel.sendMessage(text: messageText)
                                    messageText = ""
                                }
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(messageText.isEmpty ? .white.opacity(0.3) : AppDesignSystem.Colors.vibrantBlue)
                                .scaleEffect(messageText.isEmpty ? 1.0 : 1.1)
                                .animation(.spring(), value: messageText.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 110) // Clearing the Floating Tab Bar perfectly
                }
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .task {
            await viewModel.loadCurrentUser()
            await viewModel.fetchMessages()
        }
    }
}

struct MessageBubble: View {
    let message: AppMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            Text(message.content)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .foregroundColor(.white)
                .cornerRadius(18)
                .shadow(color: isCurrentUser ? AppDesignSystem.Colors.vibrantBlue.opacity(0.2) : .black.opacity(0.2), radius: 4)
            
            if !isCurrentUser { Spacer() }
        }
    }
    private var bubbleBackground: AnyView {
        if isCurrentUser {
            return AnyView(AppDesignSystem.Colors.primaryGradient)
        } else {
            return AnyView(Color.white.opacity(0.1))
        }
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [AppMessage] = []
    let conversation: Conversation
    var currentUserId: UUID?
    private let client = SupabaseManager.shared.client
    private var realtimeChannel: RealtimeChannel?

    init(conversation: Conversation) {
        self.conversation = conversation
        self.currentUserId = nil
    }

    @MainActor
    func loadCurrentUser() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            self.currentUserId = session.user.id
            
            // Start real-time subscription after user is loaded
            await subscribeToMessages()
        } catch {
            print("Auth error: \(error)")
        }
    }
    
    func fetchMessages() async {
        guard let userId = currentUserId else { return }
        do {
            let response = try await client.database
                .from("messages")
                .select()
                .or("sender_id.eq.\(userId.uuidString),receiver_id.eq.\(userId.uuidString)")
                .or("sender_id.eq.\(conversation.otherUserId.uuidString),receiver_id.eq.\(conversation.otherUserId.uuidString)")
                .order("created_at", ascending: true)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let allMessages = try decoder.decode([AppMessage].self, from: response.data)
            
            // Filter to only include messages between these two users specifically
            await MainActor.run {
                self.messages = allMessages.filter { msg in
                    (msg.senderId == userId && msg.receiverId == conversation.otherUserId) ||
                    (msg.senderId == conversation.otherUserId && msg.receiverId == userId)
                }
            }
        } catch {
            print("Chat error: \(error)")
        }
    }
    
    func sendMessage(text: String) async {
        guard let userId = currentUserId else { return }
        
        // Optimistic UI update
        let tempId = UUID()
        let newMessage = AppMessage(
            id: tempId,
            senderId: userId,
            receiverId: conversation.otherUserId,
            content: text,
            createdAt: Date()
        )
        
        await MainActor.run {
            self.messages.append(newMessage)
        }
        
        do {
            try await client.database
                .from("messages")
                .insert([
                    "sender_id": userId.uuidString,
                    "receiver_id": conversation.otherUserId.uuidString,
                    "content": text
                ])
                .execute()
        } catch {
            print("Send error: \(error)")
        }
    }
    
    private func subscribeToMessages() async {
        guard let userId = currentUserId else { return }
        
        let channelName = "chat_\(conversation.id.uuidString)"
        let channel = client.realtime.channel(channelName)
        self.realtimeChannel = channel
        
        channel.on("postgres_changes", filter: ChannelFilter(event: "INSERT", schema: "public", table: "messages")) { [weak self] _ in
            guard let self = self else { return }
            
            // When a new message arrives, refetch for this chat
            Task { @MainActor in
                await self.fetchMessages()
            }
        }
        
        channel.subscribe()
    }
    
    deinit {
        // Since deinit cannot be async, we use a Task to clean up the channel
        let channel = realtimeChannel
        Task {
            await channel?.unsubscribe()
        }
    }
}

#Preview {
    ChatView(conversation: Conversation(id: UUID(), otherUserId: UUID(), otherUserName: "Alex", otherUserAvatarURL: nil, lastMessage: "Hey!", updatedAt: Date()))
}
