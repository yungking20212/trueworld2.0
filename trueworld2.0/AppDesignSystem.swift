import SwiftUI

struct AppDesignSystem {
    struct Colors {
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "FF0080"), Color(hex: "7928CA")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let vibrantAccent = Color(hex: "00F2FE")
        static let vibrantPink = Color(hex: "FF0080")
        static let vibrantBlue = Color(hex: "00F2FE")
        static let glassBackground = Color.white.opacity(0.12)
        static let glassBorder = Color.white.opacity(0.25)
        
        static let overlayBottomGradient = LinearGradient(
            gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let vantageGlow = Color(hex: "7928CA").opacity(0.3)
    }
    
    struct Typography {
        static func premiumShadow() -> some ViewModifier {
            ShadowModifier()
        }
        
        private struct ShadowModifier: ViewModifier {
            func body(content: Content) -> some View {
                content.shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    struct Components {
        struct DynamicBackground: View {
            var body: some View {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    Circle()
                        .fill(AppDesignSystem.Colors.primaryGradient)
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: -200, y: -300)
                        .opacity(0.6)
                    
                    Circle()
                        .fill(Color(hex: "7928CA"))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: 200, y: 300)
                        .opacity(0.4)
                }
            }
        }
        
        struct AppEditField: View {
            let title: String
            @Binding var text: String
            var placeholder: String = ""
            var isMultiline: Bool = false
            
            var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.leading, 4)
                    
                    if isMultiline {
                        TextEditor(text: $text)
                            .frame(height: 100)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    } else {
                        TextField(placeholder, text: $text)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
        }
        
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
            }
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

extension View {
    func glassy(cornerRadius: CGFloat = 12) -> some View {
        self.background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppDesignSystem.Colors.glassBorder, lineWidth: 1)
            )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
