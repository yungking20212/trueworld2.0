import SwiftUI
import WebKit

struct StripeOnboardingView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                WebView(url: url)
                    .ignoresSafeArea()
                
                // Overlay for "Simulated Onboarding"
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("STRIPE SANDBOX MODE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("Complete the simulated onboarding to link your Trueworld creator ID.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: { dismiss() }) {
                            Text("FINALIZE ONBOARDING")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .colorScheme(.dark)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
