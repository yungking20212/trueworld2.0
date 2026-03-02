import SwiftUI
import Auth
import Supabase

struct ReportProblemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var problemText: String = ""
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
                    
                    Text("Report a Problem")
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
                            .shadow(color: .green.opacity(0.3), radius: 10)
                        
                        Text("Report Received")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("The neural network is processing your feedback. Our support team will investigate the disturbance.")
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
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Help Us Fine-tune the Neural Network")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Explain what's happening or what's broken in detail. Our AI will analyze your report.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextEditor(text: $problemText)
                                .frame(height: 220)
                                .padding(18)
                                .background(Color.white)
                                .cornerRadius(16)
                                .foregroundColor(.black)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.35), lineWidth: 12))
                                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                            
                            Button(action: {
                                Task {
                                    await submitReport()
                                }
                            }) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Submit Report")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(problemText.isEmpty ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(AppDesignSystem.Colors.primaryGradient))
                            .cornerRadius(18)
                            .disabled(problemText.isEmpty || isSubmitting)
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
    
    private func submitReport() async {
        guard !problemText.isEmpty else { return }
        isSubmitting = true
        
        do {
            let client = SupabaseManager.shared.client
            let user = try await client.auth.session.user
            
            let payload = ReportInsert(
                user_id: user.id.uuidString,
                message: problemText,
                category: "bug_report"
            )
            
            try await client.database
                .from("reports")
                .insert(payload)
                .execute()
            
            isSubmitted = true
        } catch {
            print("Error submitting report: \(error)")
        }
        isSubmitting = false
    }
}
