import SwiftUI

struct EngineBootView: View {
    @State private var progress: Double = 0.0
    @State private var bootText = "INITIALIZING CORE..."
    @State private var showLogo = false
    @State private var scanlineOffset: CGFloat = -400
    @Binding var isBooted: Bool
    
    let bootSequence = [
        "PROVISIONING NEURAL LAYER...",
        "SYNCING QUANTUM BUFFERS...",
        "MOUNTING AI INFRASTRUCTURE...",
        "CALIBRATING SENSORY FEED...",
        "LINK ESTABLISHED. READY."
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Retro Scanlines
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .cyan.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 400)
                .offset(y: scanlineOffset)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo Interaction
                ZStack {
                    if showLogo {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.5), radius: 20)
                            .transition(.scale.combined(with: .opacity))
                        
                        Circle()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                            .frame(width: 150, height: 150)
                            .scaleEffect(showLogo ? 1.5 : 1.0)
                            .opacity(showLogo ? 0 : 1)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showLogo)
                
                VStack(spacing: 12) {
                    Text("TRUE WORLD ENGINE")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.6))
                        .tracking(4)
                    
                    Text("VERSION 2.0.4 - NEURAL LINK")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(bootText)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 2)
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: CGFloat(progress) * 300, height: 2)
                            .shadow(color: .cyan.opacity(0.8), radius: 6)
                    }
                    .frame(width: 300)
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                scanlineOffset = 400
            }
            
            withAnimation {
                showLogo = true
            }
            
            // Loop through boot text
            for (index, text) in bootSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.7) {
                    withAnimation {
                        bootText = text
                        progress = Double(index + 1) / Double(bootSequence.count)
                    }
                }
            }
            
            // Complete boot
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation {
                    isBooted = true
                }
            }
        }
    }
}
