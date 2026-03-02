import SwiftUI

struct AppAvatar: View {
    let url: URL?
    var size: CGFloat = 50
    var showPlus: Bool = false
    var hasStories: Bool = false
    var isUploading: Bool = false
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(isUploading ? 
                    AnyShapeStyle(AngularGradient(colors: [.cyan, .purple, .pink, .orange, .cyan], center: .center)) : 
                    (hasStories ? 
                        AnyShapeStyle(LinearGradient(colors: [Color.purple, Color.pink, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)) : 
                        AnyShapeStyle(AppDesignSystem.Colors.primaryGradient))
                )
                .frame(width: size + 6, height: size + 6)
                .rotationEffect(.degrees(rotation))
                .shadow(color: isUploading ? .cyan.opacity(0.8) : .black.opacity(0.2), radius: isUploading ? 10 : 2)
                .shadow(color: isUploading ? .purple.opacity(0.5) : .clear, radius: isUploading ? 20 : 0)
                .onAppear {
                    if isUploading {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                }
                .onChange(of: isUploading) { _, newValue in
                    if newValue {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    } else {
                        rotation = 0
                    }
                }
            
            Group {
                if let url = url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderView
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black, lineWidth: 2))
            
            if showPlus {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color(hex: "FF0080"))
                    .font(.system(size: size * 0.4))
                    .offset(y: size * 0.1)
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "person.fill")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: size * 0.5))
        }
    }
}
