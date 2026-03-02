import SwiftUI

struct StatView: View {
    let count: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(count)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct TabIcon: View {
    let systemName: String
    let isActive: Bool
    let namespace: Namespace.ID
    let underlineId: String // Added to allow different IDs for different namespaces
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundColor(isActive ? .white : .white.opacity(0.35))
                .frame(height: 24)
            
            ZStack {
                Capsule()
                    .fill(Color.clear)
                    .frame(width: 40, height: 3)
                
                if isActive {
                    Capsule()
                        .fill(AppDesignSystem.Colors.primaryGradient)
                        .frame(width: 40, height: 3)
                        .matchedGeometryEffect(id: underlineId, in: namespace)
                }
            }
        }
    }
}

struct VerifiedBadge: View {
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 10))
            .foregroundColor(.blue)
    }
}

// v3 Posting Timeline Components
struct PostingTimelineView: View {
    let videos: [AppVideo]
    let onVideoTap: (AppVideo) -> Void
    
    private var groupedVideos: [(Date, [AppVideo])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: videos) { video in
            calendar.startOfDay(for: video.createdAt)
        }
        return groups.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        if videos.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.15))
                Text("Your content journey hasn't started.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.top, 100)
        } else {
            LazyVStack(alignment: .leading, spacing: 30) {
                ForEach(groupedVideos, id: \.0) { date, videos in
                    Section(header: TimelineHeader(date: date)) {
                        ForEach(videos) { video in
                            TimelineItem(video: video, onVideoTap: onVideoTap)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }
}

struct TimelineHeader: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(date.formatted(date: .abbreviated, time: .omitted).uppercased())
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.1))
                .cornerRadius(4)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct TimelineItem: View {
    let video: AppVideo
    let onVideoTap: (AppVideo) -> Void
    
    var body: some View {
        Button(action: { onVideoTap(video) }) {
            HStack(spacing: 16) {
                // Time Pillar
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 6, height: 6)
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(video.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    
                    HStack(spacing: 16) {
                        VideoThumbnailView(url: video.videoURL)
                            .frame(width: 80, height: 110)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(video.description.isEmpty ? "No description" : video.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            HStack(spacing: 12) {
                                Label("\(video.viewsCount)", systemImage: "eye.fill")
                                Label("\(video.likes)", systemImage: "heart.fill")
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
