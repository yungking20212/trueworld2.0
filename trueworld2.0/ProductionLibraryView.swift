import SwiftUI

struct ProductionLibraryView: View {
    @StateObject private var service = ProductionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduction: AIProduction? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("FILM LIBRARY")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                    Spacer()
                }
                .padding()
                
                if service.isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if service.productions.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.1))
                        Text("No productions yet")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(service.productions) { production in
                                LibraryProductionCard(production: production)
                                    .onTapGesture {
                                        selectedProduction = production
                                    }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedProduction) { production in
            ProductionDetailView(production: production)
        }
        .task {
            await service.fetchLibrary()
        }
    }
}

struct LibraryProductionCard: View {
    let production: AIProduction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .aspectRatio(0.75, contentMode: .fit)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(production.genre.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                    
                    Text(production.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            HStack {
                Label("\(production.scenes.count) Scenes", systemImage: "clapperboard.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
    }
}
