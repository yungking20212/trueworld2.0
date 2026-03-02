import SwiftUI

struct AINewsView: View {
    @StateObject private var viewModel = AINewsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppDesignSystem.Components.DynamicBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with AI Status
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("VANTAGE AI CORE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                                Text("Live Intelligence Feed")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            
                            Circle()
                                .fill(AppDesignSystem.Colors.vibrantPink)
                                .frame(width: 8, height: 8)
                                .shadow(color: AppDesignSystem.Colors.vibrantPink, radius: 4)
                                .opacity(viewModel.isLoading ? 0.3 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: viewModel.isLoading)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        if viewModel.isLoading && viewModel.newsItems.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 50)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.newsItems) { item in
                                    AINewsCard(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 120)
                }
                .refreshable {
                    await viewModel.fetchNews()
                }
            }
        }
        .task {
            await viewModel.fetchNews()
        }
    }
}

struct AINewsCard: View {
    let item: AppAINews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.category.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(item.isPrediction ? AppDesignSystem.Colors.vibrantBlue : .white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.isPrediction ? AppDesignSystem.Colors.vibrantBlue.opacity(0.1) : Color.white.opacity(0.05))
                    .cornerRadius(4)
                
                Spacer()
                
                if item.isPrediction {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("PREDICTION")
                    }
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppDesignSystem.Colors.primaryGradient)
                    .cornerRadius(20)
                } else {
                    Text(item.createdAt.formatted(.relative(presentation: .numeric)))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            Text(item.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Text(item.content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                NavigationLink(destination: AIAnalyticsView()) {
                    Text("Read Deep Analysis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppDesignSystem.Colors.primaryGradient)
                        .cornerRadius(8)
                        .shadow(color: Color(hex: "FF0080").opacity(0.3), radius: 5)
                }
            }
        }
        .padding(16)
        .glassy()
    }
}

#Preview {
    ZStack {
        AppDesignSystem.Components.DynamicBackground()
        AINewsView()
    }
}
