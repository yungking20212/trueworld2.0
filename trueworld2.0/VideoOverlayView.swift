import SwiftUI
import CoreLocation

struct VideoOverlayView: View {
    let video: AppVideo
    var onLike: () -> Void
    
    @State private var isShowingComments = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Shadow Gradient for text legibility
            AppDesignSystem.Colors.overlayBottomGradient
                .frame(height: 250)
                .allowsHitTesting(false)
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 0) {
                    // Left Side: Info
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Text(video.username)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if video.authorMonetizationEnabled && video.authorRevenueMultiplier > 1 {
                                Text("\(video.authorRevenueMultiplier)X")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        LinearGradient(colors: [.purple, .pink, .orange], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(4)
                                    .shadow(color: .purple.opacity(0.5), radius: 4)
                            }
                        }
                        .modifier(AppDesignSystem.Typography.premiumShadow())
                        
                        if let lat = video.latitude, let long = video.longitude {
                            HStack(spacing: 4) {
                                Image(systemName: video.isLocationProtected ? "shield.fill" : "location.fill")
                                    .font(.system(size: 10))
                                Text(calculateDistance(lat: lat, long: long))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                
                                if video.isLocationProtected {
                                    Text("PROTECTED")
                                        .font(.system(size: 8, weight: .black))
                                        .padding(.leading, 2)
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(video.isLocationProtected ? AppDesignSystem.Colors.vibrantPink.opacity(0.4) : AppDesignSystem.Colors.vibrantBlue.opacity(0.3))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            .modifier(AppDesignSystem.Typography.premiumShadow())
                        }
                        
                        Text(video.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .modifier(AppDesignSystem.Typography.premiumShadow())
                        
                        HStack(spacing: 10) {
                            Image(systemName: "music.note")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            
                            ScrollingText(text: video.musicTitle)
                                .frame(width: 140)
                            
                            MusicWaveform()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Right Side: Actions
                    VStack(spacing: 22) {
                        // Profile Avatar (Creator)
                        NavigationLink(destination: PeerProfileView(viewModel: PeerProfileViewModel(userId: video.authorId))) {
                            AppAvatar(url: video.userAvatarURL, size: 48, showPlus: false)
                                .shadow(radius: 4)
                        }
                        
                        // Like Button
                        Button(action: {
                            onLike()
                            triggerHaptic(style: .heavy)
                        }) {
                            InteractionButton(icon: video.isLiked ? "heart.fill" : "heart", 
                                              count: video.likes, 
                                              color: video.isLiked ? .red : .white)
                        }
                        
                        // Comment Button
                        Button(action: { 
                            isShowingComments = true 
                            triggerHaptic(style: .light)
                        }) {
                            InteractionButton(icon: "message.fill", count: video.comments)
                        }
                        
                        // Share Button
                        Button(action: {
                            shareVideo()
                            triggerHaptic(style: .medium)
                        }) {
                            InteractionButton(icon: "paperplane.fill", count: video.shares)
                        }
                        
                        // Rotating Music Icon
                        MusicIcon()
                        
                    }
                    .padding(.trailing, 12)
                }
                .padding(.bottom, 90) // Push primary controls above the floating tab bar
                
                // Playback Progress Bar - Absolute Bottom
                PlaybackProgressBar()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $isShowingComments) {
            CommentsSheetView(videoId: video.id)
        }
    }
    
    private func calculateDistance(lat: Double, long: Double) -> String {
        guard let userLoc = LocationManager.shared.location else { return "NEARBY" }
        let postLoc = CLLocation(latitude: lat, longitude: long)
        let distanceInMeters = userLoc.distance(from: postLoc)
        let distanceInMiles = distanceInMeters / 1609.34
        
        if distanceInMiles < 0.1 {
            return "HERE"
        } else if distanceInMiles < 1.0 {
            return String(format: "%.1f MI", distanceInMiles)
        } else {
            return String(format: "%d MI", Int(distanceInMiles))
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func shareVideo() {
        let deepLink = "https://trueworldapp.com/v/\(video.id.uuidString)"
        let text = "Check out this visual broadcast on trueworld: \(deepLink)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

struct PlaybackProgressBar: View {
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 2)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: progress * geometry.size.width, height: 2)
                    .shadow(color: AppDesignSystem.Colors.vibrantBlue.opacity(0.8), radius: 6)
                    .shadow(color: AppDesignSystem.Colors.vibrantPink.opacity(0.8), radius: 10)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 2)
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                progress = 1.0
            }
        }
    }
}

struct MusicWaveform: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 1.5, height: animate ? CGFloat.random(in: 4...10) : 6)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct InteractionButton: View {
    let icon: String
    let count: Int
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.glassBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [Color.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                    .shadow(color: color.opacity(0.2), radius: 12)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 4)
            }
            
            Text(count > 0 ? "\(count)" : "0")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .modifier(AppDesignSystem.Typography.premiumShadow())
        }
    }
}

struct ScrollingText: View {
    let text: String
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: offset)
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        offset = -proxy.size.width - 50
                    }
                }
        }
        .frame(width: 120, height: 20)
        .clipped()
    }
}

struct MusicIcon: View {
    @State private var isRotating = 0.0
    
    var body: some View {
        ZStack {
            // Expanding circle streams
            MusicStreamView()
            
            Circle()
                .fill(Color.black)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 8))
            
            Circle()
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]), center: .center),
                    lineWidth: 1
                )
            
            Image(systemName: "music.note")
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
        .rotationEffect(.degrees(isRotating))
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                isRotating = 360.0
            }
        }
    }
}

struct MusicStreamView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.0)
                    .frame(width: 30, height: 30)
                    .scaleEffect(animate ? 2.0 : 1.0)
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 3)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 1.0),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

