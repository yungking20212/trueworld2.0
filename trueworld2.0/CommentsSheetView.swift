import SwiftUI
import Supabase
internal import _Helpers

struct CommentsSheetView: View {
    @StateObject private var viewModel: CommentsViewModel
    @State private var replyingTo: UUID? = nil
    @State private var newCommentText: String = ""
    @Environment(\.dismiss) var dismiss
    
    init(videoId: UUID) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(videoId: videoId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(viewModel.comments.count) Comments")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding()
            
            Divider()
            
            // Comment List
            if viewModel.isLoading && viewModel.comments.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.comments.filter { $0.parentId == nil }) { comment in
                            VStack(alignment: .leading, spacing: 15) {
                                CommentRow(comment: comment,
                                           onReply: { replyingTo = comment.id },
                                           onLike: { id in
                                               // UI update is handled via Realtime/Refetch or manual increment
                                               // For now, let's keep it snappy with local increment + server call
                                               if let idx = viewModel.comments.firstIndex(where: { $0.id == id }) {
                                                   viewModel.comments[idx].likes += 1
                                               }
                                               Task { await viewModel.likeComment(id) }
                                           })
                                
                                // Replies
                                ForEach(viewModel.comments.filter { $0.parentId == comment.id }) { reply in
                                    CommentRow(comment: reply,
                                               onReply: { replyingTo = comment.id },
                                               onLike: { id in
                                                   if let idx = viewModel.comments.firstIndex(where: { $0.id == id }) {
                                                       viewModel.comments[idx].likes += 1
                                                   }
                                                   Task { await viewModel.likeComment(id) }
                                               })
                                    .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            if let replyId = replyingTo, let parent = viewModel.comments.first(where: { $0.id == replyId }) {
                HStack {
                    Text("Replying to @\(parent.username)")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Spacer()
                    Button(action: { replyingTo = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                AppAvatar(url: nil, size: 36)
                
                TextField("Add a comment...", text: $newCommentText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: postComment) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(newCommentText.isEmpty ? .gray.opacity(0.3) : .blue)
                }
                .disabled(newCommentText.isEmpty || viewModel.isLoading)
            }
            .padding()
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.fetchComments()
        }
    }
    
    private func postComment() {
        guard !newCommentText.isEmpty else { return }
        let text = newCommentText
        newCommentText = ""
        let parent = replyingTo
        replyingTo = nil
        
        Task {
            await viewModel.postComment(text: text, parentId: parent)
        }
    }
}

struct CommentRow: View {
    let comment: AppComment
    var onReply: (() -> Void)?
    var onLike: ((UUID) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AppAvatar(url: comment.userAvatarURL, size: 34)
                .shadow(color: .black.opacity(0.1), radius: 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(comment.username)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.9))
                    
                    if comment.followerCount >= 50 {
                        VerifiedBadge()
                    }
                    
                    if let _ = comment.parentId {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("reply")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }

                Text(comment.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(2)

                HStack(spacing: 16) {
                    Text(comment.createdAt.formatted(.relative(presentation: .numeric)))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))

                    Button(action: { onReply?() }) {
                        Text("Reply")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            VStack(spacing: 4) {
                Button(action: { onLike?(comment.id) }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(comment.likes > 0 ? .pink : .gray.opacity(0.3))
                        .padding(8)
                        .background(Circle().fill(Color.gray.opacity(0.05)))
                }

                Text("\(comment.likes)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
    }
}
