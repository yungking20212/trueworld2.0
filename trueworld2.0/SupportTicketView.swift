import SwiftUI
import Auth
import Supabase

struct SupportTicketView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var isSubmitting: Bool = false
    @State private var isSubmitted: Bool = false

    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Contact Support")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                if isSubmitted {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Support Request Sent")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("Our support team will respond via your account email.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button(action: { dismiss() }) {
                            Text("Return to Hub")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(AppDesignSystem.Colors.primaryGradient)
                                .cornerRadius(14)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Send a message to Support")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            TextField("Subject", text: $subject)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .foregroundColor(.black)

                            TextEditor(text: $message)
                                .frame(height: 220)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .foregroundColor(.black)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.35), lineWidth: 10))
                                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)

                            Button(action: {
                                Task { await submitTicket() }
                            }) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Send to Support")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill((subject.isEmpty || message.isEmpty) ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(AppDesignSystem.Colors.primaryGradient))
                            )
                            .disabled(subject.isEmpty || message.isEmpty || isSubmitting)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .cornerRadius(24)
                        .padding(20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func submitTicket() async {
        guard !subject.isEmpty && !message.isEmpty else { return }
        isSubmitting = true

        do {
            let client = SupabaseManager.shared.client
            let user = try await client.auth.session.user

            let payload = SupportInsert(
                user_id: user.id.uuidString,
                subject: subject,
                message: message,
                status: "open"
            )

            try await client.database
                .from("support_tickets")
                .insert(payload)
                .execute()

            isSubmitted = true
        } catch {
            print("Error submitting support ticket: \(error)")
        }

        isSubmitting = false
    }
}

public struct SupportInsert: Encodable, Sendable {
    public let user_id: String
    public let subject: String
    public let message: String
    public let status: String

    public init(user_id: String, subject: String, message: String, status: String = "open") {
        self.user_id = user_id
        self.subject = subject
        self.message = message
        self.status = status
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(subject, forKey: .subject)
        try container.encode(message, forKey: .message)
        try container.encode(status, forKey: .status)
    }

    enum CodingKeys: String, CodingKey {
        case user_id, subject, message, status
    }
}
