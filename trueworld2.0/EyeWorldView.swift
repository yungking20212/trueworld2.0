import SwiftUI
import Combine
import MapKit
import Supabase

struct EyeWorldView: View {
    @StateObject private var viewModel = EyeWorldViewModel()
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var selectedMarker: WorldMarker? = nil
    @State private var position: MapCameraPosition = .automatic
    @State private var hasCentredOnUser = false
    @State private var isAiScanning = false
    @State private var aiStatus = "NEURAL_SCAN_ACTIVE"
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var storyToShow: AppStory? = nil
    @State private var showingStoryViewer = false
    @ObservedObject private var uiState = AppGlobalUIState.shared
    @State private var activeSidebarTab: SidebarTab = .system
    @State private var mapFilter: MapFilter = .all
    
    enum SidebarTab: String, CaseIterable {
        case system = "SYSTEM"
        case rankings = "RANKINGS"
        case pulse = "PULSE"
    }
    
    enum MapFilter: String, CaseIterable {
        case all = "ALL"
        case night = "NIGHT_MODE"
        case live = "LIVE_PULSE"
        case travel = "TRAVEL"
        case country = "COUNTRY_TAKEOVER"
    }
    
    var body: some View {
        ZStack {
            // The Map (Root Background)
            Map(position: $position) {
                UserAnnotation() // Show the blue dot
                
                if mapFilter == .all || mapFilter == .night || mapFilter == .live {
                    ForEach(viewModel.worldMarkers) { marker in
                        Annotation(marker.title, coordinate: marker.coordinate) {
                            VideoMapAnchor(marker: marker)
                                .onTapGesture {
                                    triggerAiLocator(for: marker)
                                }
                        }
                    }
                    
                    // v3 Hot Zones Layer
                    ForEach(viewModel.hotZones) { zone in
                        Annotation(zone.name, coordinate: zone.coordinate) {
                            HotZoneMarker(zone: zone)
                        }
                    }
                }
                
                if mapFilter == .all || mapFilter == .travel {
                    ForEach(viewModel.storyMarkers) { marker in
                        Annotation(marker.title, coordinate: marker.coordinate) {
                            StoryMapAnchor(marker: marker)
                                .onTapGesture {
                                    triggerAiLocator(for: marker)
                                }
                        }
                    }
                }
                
                // v3 Country Takeover Layer
                if mapFilter == .country {
                    ForEach(viewModel.countryDominance) { dominance in
                        Annotation(dominance.country, coordinate: dominance.coordinate) {
                            CountryDominanceMarker(dominance: dominance)
                        }
                    }
                }
                
                // v3 Own Your Block: Show user pulse if they dominate their radius
                if viewModel.isUserBlockOwner, let userLoc = locationManager.location {
                    Annotation("DOMINATOR", coordinate: userLoc.coordinate) {
                        BlockDominatorPulse()
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
            .colorScheme(.dark)
            .ignoresSafeArea() // Force edge-to-edge
            .onMapCameraChange { context in
                viewModel.fetchWorldPulse(region: context.region)
                
                // v3 Orbital Sound: Handle Space Noise based on zoom level
                SpaceNoiseManager.shared.updateSpaceAmbient(zoomLevel: context.region.span.latitudeDelta)
            }
            
            if !uiState.isEyeWorldUiHidden {
                // Top Layer: Map Filters
                VStack {
                    HStack(spacing: 12) {
                        ForEach(MapFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    mapFilter = filter
                                }
                                triggerHaptic(style: .light)
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(mapFilter == filter ? .black : .white.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(mapFilter == filter ? Color.cyan : Color.black.opacity(0.4))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.top, 54)
                    Spacer()
                }

                // Left Sidebar: Neural Command Center
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            // Search is now part of the command center
                            GlassmorphicSearchField(text: $searchText, placeholder: "SEARCH...", isSearching: isSearching) {
                                Task {
                                    isSearching = true
                                    if let creator = await viewModel.searchCreator(query: searchText) {
                                        triggerAiLocator(for: creator)
                                    }
                                    isSearching = false
                                }
                            }
                            .frame(width: 180)
                            
                            // Tab Switcher
                            HStack(spacing: 0) {
                                ForEach(SidebarTab.allCases, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            activeSidebarTab = tab
                                        }
                                        triggerHaptic(style: .light)
                                    }) {
                                        Text(tab.rawValue)
                                            .font(.system(size: 8, weight: .black, design: .monospaced))
                                            .foregroundColor(activeSidebarTab == tab ? .cyan : .white.opacity(0.3))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(activeSidebarTab == tab ? Color.white.opacity(0.05) : Color.clear)
                                    }
                                }
                            }
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            
                            // Active Tab Content
                            ZStack {
                                switch activeSidebarTab {
                                case .system:
                                    VStack(alignment: .leading, spacing: 12) {
                                        HUDPane(isAiScanning: isAiScanning, aiStatus: aiStatus, activeScanners: viewModel.activeScanners)
                                        
                                        // Integrated Statistics (formerly debug badge)
                                        VStack(alignment: .leading, spacing: 4) {
                                            StatLine(label: "VIDEOS", value: "\(viewModel.worldMarkers.count)")
                                            StatLine(label: "STORIES", value: "\(viewModel.storyMarkers.count)")
                                            StatLine(label: "FRIENDS", value: "\(viewModel.onlineFriends.count)")
                                            if let error = viewModel.errorMessage {
                                                Text("ERR: \(error)")
                                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(10)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)
                                    }
                                    .transition(.opacity)
                                    
                                case .rankings:
                                    GlobalLeaderboardSidebar(creators: viewModel.topCreators) { creator in
                                        // Trigger search for this creator to locate them on map
                                        Task {
                                            if let marker = await viewModel.searchCreator(query: creator.username ?? "") {
                                                triggerAiLocator(for: marker)
                                            }
                                        }
                                    }
                                    .transition(.opacity)
                                    
                                case .pulse:
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("ONLINE FEED")
                                            .font(.system(size: 8, weight: .black, design: .monospaced))
                                            .foregroundColor(.cyan)
                                        
                                        ScrollView(showsIndicators: false) {
                                            VStack(spacing: 12) {
                                                ForEach(viewModel.onlineFriends) { friend in
                                                    HStack(spacing: 10) {
                                                        ZStack(alignment: .bottomTrailing) {
                                                            AppAvatar(url: friend.avatarURL, size: 32)
                                                            Circle()
                                                                .fill(Color.green)
                                                                .frame(width: 8, height: 8)
                                                                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                                                        }
                                                        
                                                        Text("@\(friend.username?.uppercased() ?? "USER")")
                                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                            .foregroundColor(.white)
                                                        
                                                        Spacer()
                                                    }
                                                }
                                            }
                                        }
                                        .frame(height: 200)
                                    }
                                    .padding(12)
                                    .background(Color.black.opacity(0.4))
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                    .transition(.opacity)
                                }
                            }
                            .frame(width: 180)
                        }
                        .padding(.top, 100)
                        .padding(.leading, 16)
                        .scaleEffect(uiState.isEyeWorldUiHidden ? 0.8 : 1.0)
                        .opacity(uiState.isEyeWorldUiHidden ? 0.0 : 1.0)
                        
                        Spacer()
                    }
                    Spacer()
                }

                // Bottom Controls: Teleport & Search
                VStack {
                    Spacer()
                    WorldControls(onTeleport: { city in
                        withAnimation(.spring()) {
                            position = .region(city.region)
                        }
                    })
                    .padding(.bottom, 120) // Push above the floating tab bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // UI Toggle Button (Eye Icon)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            uiState.isEyeWorldUiHidden.toggle()
                            uiState.isTabBarHidden = uiState.isEyeWorldUiHidden
                        }
                        triggerHaptic(style: .medium)
                    }) {
                        Image(systemName: uiState.isEyeWorldUiHidden ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                            .shadow(color: Color.cyan.opacity(0.2), radius: 10)
                    }
                    .padding(.top, 54)
                    .padding(.trailing, 16)
                }
                Spacer()
            }

        }
        .ignoresSafeArea() // Ensure ZStack itself spans the entire screen
        .task {
            await viewModel.joinNeuralMap()
            viewModel.fetchWorldPulse()
        }
        .sheet(item: $selectedMarker) { marker in
            if !marker.isStory {
                VideoDetailView(videoId: marker.id)
            }
        }
        .fullScreenCover(isPresented: $showingStoryViewer) {
            if let story = storyToShow {
                StoryViewer(stories: [story], isPresented: $showingStoryViewer)
            }
        }
        .onDisappear {
            Task { await viewModel.leaveNeuralMap() }
        }
        .onAppear {
            locationManager.startUpdating()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let loc = newLocation, !hasCentredOnUser {
                let initialRegion = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                
                withAnimation(.spring()) {
                    position = .region(initialRegion)
                    hasCentredOnUser = true
                }
                
                // Fetch pulse for the user's actual location
                viewModel.fetchWorldPulse(region: initialRegion)
            }
        }
    }
    
    private func triggerAiLocator(for marker: WorldMarker) {
        isAiScanning = true
        aiStatus = "SUPERGEN_AI_LOCATOR_ZOOM_IN"
        triggerHaptic(style: .heavy)
        
        // High-fidelity zoom animation
        withAnimation(.spring(response: 1.2, dampingFraction: 0.75, blendDuration: 0.8)) {
            position = .region(MKCoordinateRegion(
                center: marker.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
        
        Task {
            // Wait for the cinematic zoom to complete halfway for a seamless transition
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if marker.isStory {
                // Fetch full story details
                if let story = await viewModel.fetchStoryDetails(id: marker.id) {
                    self.storyToShow = story
                    self.showingStoryViewer = true
                }
            } else {
                selectedMarker = marker
            }
            isAiScanning = false
            aiStatus = "NEURAL_SCAN_ACTIVE"
        }
    }

    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Previews

struct EyeWorldView_Previews: PreviewProvider {
    static var previews: some View {
        EyeWorldView()
            .previewDevice("iPhone 14 Pro")
    }
}

// MARK: - Components

struct VideoMapAnchor: View {
    let marker: WorldMarker
    @State private var animate = false
    
    // Calculate size based on rank/views
    private var markerColor: Color {
        if marker.isWorldDominator {
            return .yellow // Golden Glow for #1
        } else if let rank = marker.globalRank, rank <= 3 {
            return AppDesignSystem.Colors.vibrantPink
        } else {
            return AppDesignSystem.Colors.vibrantBlue
        }
    }
    
    private var scaleMultiplier: CGFloat {
        if marker.isWorldDominator {
            return 1.8 // Mega Scale for Dominator
        } else if let rank = marker.globalRank, rank <= 3 {
            return 1.3
        } else {
            return 1.0
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Dominator Glow Aura
                if marker.isWorldDominator {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .blur(radius: 10)
                        .scaleEffect(animate ? 1.4 : 1.0)
                }

                Circle()
                    .fill(markerColor)
                    .frame(width: 40 * scaleMultiplier, height: 40 * scaleMultiplier)
                    .shadow(color: markerColor, radius: marker.isWorldDominator ? 20 : 10)
                
                if marker.isWorldDominator {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .offset(y: -28)
                        .shadow(color: .black, radius: 4)
                } else if let rank = marker.globalRank, rank <= 10 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .offset(y: -22 * scaleMultiplier)
                }
                
                if marker.isRisingStar {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                        .offset(x: 20, y: -10)
                        .shadow(color: .cyan, radius: 4)
                }
                
                Image(systemName: "play.fill")
                    .font(.system(size: 14 * scaleMultiplier, weight: .black))
                    .foregroundColor(.white)
                
                // Pulsing outer ring
                Circle()
                    .stroke(markerColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 50 * scaleMultiplier, height: 50 * scaleMultiplier)
                    .scaleEffect(animate ? 1.6 : 1.0)
                    .opacity(animate ? 0 : 1)
            }
            
            // Stem
            Rectangle()
                .fill(markerColor)
                .frame(width: 2, height: 10)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

struct StoryMapAnchor: View {
    let marker: WorldMarker
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppDesignSystem.Colors.primaryGradient, lineWidth: 2)
                .frame(width: 32, height: 32)
                .scaleEffect(animate ? 1.4 : 1.0)
                .opacity(animate ? 0 : 1)
            
            Circle()
                .fill(AppDesignSystem.Colors.primaryGradient)
                .frame(width: 24, height: 24)
                .shadow(color: .purple.opacity(0.5), radius: 8)
            
            Image(systemName: "camera.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

struct HotZoneMarker: View {
    let zone: HotZone
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Pulse Heat Aura (Faction Glow)
            Circle()
                .stroke(zone.color.opacity(0.3), lineWidth: 4)
                .frame(width: 100, height: 100)
                .scaleEffect(animate ? 1.5 : 0.8)
                .opacity(animate ? 0 : 0.6)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 8))
                    Text(zone.name)
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(zone.color)
                .cornerRadius(4)
                
                if let controller = zone.controller {
                    Text("CONTROLLED BY @\(controller.uppercased())")
                        .font(.system(size: 6, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(4)
                }

                Text("\(zone.trendingCount) TRENDING")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct CountryDominanceMarker: View {
    let dominance: CountryDominance
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .blur(radius: 20)
                
                VStack(spacing: 2) {
                    Text(dominance.flagEmoji)
                        .font(.system(size: 24))
                    Text(dominance.country)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            
            Text("DOMINATED BY @\(dominance.controller.uppercased())")
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.cyan)
                .cornerRadius(4)
            
            HStack(spacing: 4) {
                Text("STRATEGIC SCORE: \(Int(dominance.dominanceScore * 100))%")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct BlockDominatorPulse: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.4))
                .frame(width: 80, height: 80)
                .scaleEffect(animate ? 1.5 : 1.0)
                .blur(radius: 20)
                .opacity(animate ? 0 : 1)
            
            Circle()
                .stroke(Color.yellow, lineWidth: 2)
                .frame(width: 40, height: 40)
            
            Image(systemName: "crown.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

struct HUDPane: View {
    let isAiScanning: Bool
    let aiStatus: String
    let activeScanners: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 8))
                Text("SYSTEM_BOOT_v1.0.4")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
            }
            .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                if let loc = LocationManager.shared.location {
                    Text("LAT: \(String(format: "%.4f", loc.coordinate.latitude))")
                    Text("LONG: \(String(format: "%.4f", loc.coordinate.longitude))")
                } else {
                    Text("LAT: SEARCHING...")
                    Text("LONG: SEARCHING...")
                }
                
               // Neural Status Indicators
            HStack(spacing: 12) {
                StatusItem(label: "STATUS", value: aiStatus, color: isAiScanning ? .green : .cyan)
                
                Divider()
                    .frame(height: 10)
                    .background(Color.white.opacity(0.2))
                
                StatusItem(label: "SCANNERS", value: "\(activeScanners)", color: .cyan)
            }
            .animation(.easeInOut(duration: 0.2).repeatForever(), value: isAiScanning)
            }
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.6))
        }
        .padding(10)
        .background(Color.black.opacity(0.6))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }
}

struct HUDOverlay: View {
    let isAiScanning: Bool
    let aiStatus: String
    
    var body: some View {
        ZStack {
            // Scanlines
            VStack(spacing: 4) {
                ForEach(0..<100) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.02))
                        .frame(height: 1)
                }
            }
            
            // Corners
            VStack {
                HStack {
                    HUDCorner(rotation: 0)
                    Spacer()
                    HUDCorner(rotation: 90)
                }
                Spacer()
                HStack {
                    HUDCorner(rotation: 270)
                    Spacer()
                    HUDCorner(rotation: 180)
                }
            }
            .padding(20)
        }
    }
}

struct HUDCorner: View {
    let rotation: Double
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        .frame(width: 20, height: 20)
        .rotationEffect(.degrees(rotation))
    }
}

struct FriendsPulseDrawer: View {
    let friends: [AppUser]
    
    var body: some View {
        VStack(spacing: 16) {
            // Ranking Header
            Circle()
                .fill(AppDesignSystem.Colors.primaryGradient)
                .frame(width: 4, height: 20)
                .padding(.bottom, 4)

            ForEach(friends) { friend in
                ZStack(alignment: .bottomTrailing) {
                    AppAvatar(url: friend.avatarURL, size: 44)
                        .shadow(color: Color.black.opacity(0.5), radius: 4)
                    
                    // Green online indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .shadow(color: .green, radius: 4)
                }
            }
            
            if friends.isEmpty {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.trailing, 20)
    }
}

struct GlobalLeaderboardSidebar: View {
    let creators: [TopCreatorDTO]
    let onSelect: (TopCreatorDTO) -> Void
    
    private func prizeForRank(_ rank: Int) -> String? {
        switch rank {
        case 1: return "$1,000"
        case 2: return "$500"
        case 3: return "$200"
        case 4: return "$100"
        case 5: return "$50"
        case 6: return "$20"
        default: return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Leaderboard Header
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 8))
                Text("NEURAL_DAILY_PRIZEPOOL")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
            }
            .foregroundColor(.cyan)
            .padding(.bottom, 2)
            
            ForEach(creators) { creator in
                Button(action: { onSelect(creator) }) {
                    HStack(spacing: 8) {
                        // Rank Badge
                        ZStack {
                            Circle()
                                .fill(creator.daily_rank == 1 ? Color.yellow : (creator.daily_rank ?? 10 <= 3 ? AppDesignSystem.Colors.vibrantPink : Color.white.opacity(0.1)))
                                .frame(width: 22, height: 22)
                            
                            Text("\(creator.daily_rank ?? 0)")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(creator.daily_rank ?? 10 <= 3 ? (creator.daily_rank == 1 ? .black : .white) : .white.opacity(0.6))
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("@\(creator.username?.uppercased() ?? "CREATOR")")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                HStack(spacing: 2) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 6))
                                    Text("\(creator.view_count ?? 0)")
                                        .font(.system(size: 6, weight: .semibold, design: .monospaced))
                                }
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 6))
                                    Text("L\(creator.level ?? 0)")
                                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.cyan)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 6))
                                    Text("\(String(format: "%.1f", creator.engagement_score ?? 0))%")
                                        .font(.system(size: 6, weight: .black, design: .monospaced))
                                }
                                .foregroundColor(.green)
                            }
                            .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        // Prize Display
                        if let prize = prizeForRank(creator.daily_rank ?? 0) {
                            Text(prize)
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundColor(creator.daily_rank == 1 ? .yellow : .green)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(creator.daily_rank == 1 ? Color.yellow.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                }
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color.black.opacity(0.4))
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct GlassmorphicSearchField: View {
    @Binding var text: String
    let placeholder: String
    let isSearching: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if isSearching {
                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)
            }
            
            TextField("", text: $text, prompt: 
                Text(placeholder)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            )
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .tint(.cyan)
            .autocapitalization(.allCharacters)
            .onSubmit(onSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.5))
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 10)
    }
}

struct WorldControls: View {
    let onTeleport: (CityRegion) -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(CityRegion.predefined) { city in
                Button(action: { onTeleport(city) }) {
                    VStack(spacing: 4) {
                        Text(city.name.uppercased())
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 4, height: 4)
                    }
                    .frame(width: 70, height: 50)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
            }
        }
    }
}

struct StatLine: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(.cyan)
        }
    }
}

struct StatusItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 5, weight: .black, design: .monospaced))
                .foregroundColor(color.opacity(0.5))
            Text(value)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - Models & ViewModels

struct WorldMarker: Identifiable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let views: Int
    let globalRank: Int?
    let neuralScore: Int?
    var followerCount: Int? = nil
    var followingCount: Int? = nil
    var xp: Int? = nil
    var monetizationEnabled: Bool? = nil
    var revenueCents: Int? = nil
    var isStory: Bool = false
    
    // v3 Competitive Features
    var momentumScore: Double? = nil
    var isRisingStar: Bool = false
    var isWorldDominator: Bool { globalRank == 1 }
    var city: String? = nil
}

struct CountryDominance: Identifiable {
    let id = UUID()
    let country: String
    let coordinate: CLLocationCoordinate2D
    let controller: String
    let dominanceScore: Double // 0.0 to 1.0
    let flagEmoji: String
}

struct HotZone: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let intensity: Double // 0.0 to 1.0 (heat)
    let trendingCount: Int
    let color: Color // Faction Color (Green, Blue, Red, Purple)
    let controller: String? // Which creator owns the block
}

struct CityRegion: Identifiable {
    let id = UUID()
    let name: String
    let region: MKCoordinateRegion
    
    static let predefined = [
        CityRegion(name: "DALLAS", region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))),
        CityRegion(name: "NYC", region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))),
        CityRegion(name: "TOKYO", region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)))
    ]
}

// Special DTO for Eye World Pulse RPC
struct EyeWorldVideoDTO: Decodable {
    let id: UUID
    let username: String?
    let author_id: UUID?
    let description: String?
    let likes: Int?
    let comments: Int?
    let shares: Int?
    let views_count: Int?
    let latitude: Double?
    let longitude: Double?
    let neural_score: Int?
    let global_rank: Int?
    let follower_count: Int?
    let following_count: Int?
    let xp: Int?
    let monetization_enabled: Bool?
    let revenue_cents: Int?
    
    // v3 Additions
    let momentum_score: Double?
    let is_rising_star: Bool?
    let city_name: String?
}

struct TopCreatorDTO: Decodable, Identifiable {
    var id: UUID { author_id }
    let author_id: UUID
    let username: String?
    let like_count: Int?
    let view_count: Int?
    let engagement_score: Double?
    let level: Int?
    let xp: Int?
    let daily_rank: Int?
}

struct RawStoryMarkerDTO: Decodable {
    let id: UUID
    let latitude: Double?
    let longitude: Double?
    let user_id: UUID
}

struct MinimalProfileDTO: Decodable {
    let id: UUID
    let username: String?
}

struct StoryMarkerDTO: Decodable {
    let id: UUID
    let latitude: Double?
    let longitude: Double?
    let author: StoryAuthorDTO?
    
    struct StoryAuthorDTO: Decodable {
        let username: String?
        let avatar_url: String?
    }
}

@MainActor
class EyeWorldViewModel: ObservableObject {
    
    @Published var worldMarkers: [WorldMarker] = []
    @Published var storyMarkers: [WorldMarker] = []
    @Published var onlineFriends: [AppUser] = []
    @Published var topCreators: [TopCreatorDTO] = []
    @Published var hotZones: [HotZone] = [] // v3 Competitive Layer
    @Published var countryDominance: [CountryDominance] = [] // v3 Strategic Layer
    @Published var isUserBlockOwner = false // v3 'Own Your Block'
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var activeScanners: Int = 0
    @Published var worldPulseStatus: String = "STABLE"
    
    private let client = SupabaseManager.shared.client
    private let neuralManager = NeuralNetworkManager.shared
    private var inFlightTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        neuralManager.$activeScanners
            .assign(to: \.activeScanners, on: self)
            .store(in: &cancellables)
            
        neuralManager.$latestWorldPulse
            .assign(to: \.worldPulseStatus, on: self)
            .store(in: &cancellables)
    }
    
    func joinNeuralMap() async {
        if let user = ProfileManager.shared.currentUser {
            await neuralManager.joinNeuralMap(user: user)
        }
    }
    
    func leaveNeuralMap() async {
        await neuralManager.leaveNeuralMap()
    }
    
    func fetchWorldPulse(region: MKCoordinateRegion? = nil) {
        inFlightTask?.cancel()
        
        inFlightTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Allow small delay to avoid excessive RPC calls during active panning
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            
            await MainActor.run { self.isLoading = true }
            
            do {
                let latDelta = region?.span.latitudeDelta ?? 90
                let longDelta = region?.span.longitudeDelta ?? 180
                let centerLat = region?.center.latitude ?? 0
                let centerLong = region?.center.longitude ?? 0
                
                let minLat = region != nil ? centerLat - (latDelta / 2) : -90
                let maxLat = region != nil ? centerLat + (latDelta / 2) : 90
                let minLong = region != nil ? centerLong - (longDelta / 2) : -180
                let maxLong = region != nil ? centerLong + (longDelta / 2) : 180

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                // 1. Fetch Videos via RPC
                var newWorldMarkers: [WorldMarker] = []
                do {
                    let response = try await client.database
                        .rpc("get_world_pulse_v2", params: [
                            "min_lat": minLat,
                            "max_lat": maxLat,
                            "min_long": minLong,
                            "max_long": maxLong
                        ])
                        .execute()
                    
                    if Task.isCancelled { return }
                    let videos = try decoder.decode([EyeWorldVideoDTO].self, from: response.data)
                    
                    // Real Handle Resolution: Priority to current profiles
                    let authorIds = Array(Set(videos.compactMap { $0.author_id?.uuidString }))
                    var realProfiles: [String: String] = [:] 
                    if !authorIds.isEmpty {
                        let profileResponse = try await client.database
                            .from("profiles")
                            .select("id, username")
                            .in("id", value: authorIds)
                            .execute()
                        let profiles = try decoder.decode([MinimalProfileDTO].self, from: profileResponse.data)
                        for p in profiles { realProfiles[p.id.uuidString] = p.username }
                    }

                    newWorldMarkers = videos.compactMap { video in
                        let handle = realProfiles[video.author_id?.uuidString ?? ""] ?? video.username ?? "Unknown Creator"
                        let baseLat = region?.center.latitude ?? LocationManager.shared.location?.coordinate.latitude ?? 32.7767
                        let baseLong = region?.center.longitude ?? LocationManager.shared.location?.coordinate.longitude ?? -96.7970
                        
                        let lat = video.latitude ?? baseLat + Double.random(in: -0.05...0.05)
                        let long = video.longitude ?? baseLong + Double.random(in: -0.05...0.05)
                        
                        return WorldMarker(
                            id: video.id,
                            title: handle,
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long),
                            views: video.views_count ?? 0,
                            globalRank: video.global_rank,
                            neuralScore: video.neural_score,
                            followerCount: video.follower_count,
                            followingCount: video.following_count,
                            xp: video.xp,
                            monetizationEnabled: video.monetization_enabled,
                            revenueCents: video.revenue_cents,
                            momentumScore: video.momentum_score,
                            isRisingStar: video.is_rising_star ?? false,
                            city: video.city_name
                        )
                    }
                    
                    // v3 Force Hot Zones Simulation (Real data would be an RPC)
                    // Upgraded to GTA-style Creator Blocks with Faction Colors
                    self.hotZones = [
                        HotZone(name: "NYC_CORE", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), intensity: 0.9, trendingCount: 1420, color: .purple, controller: "ZENITH_ONE"),
                        HotZone(name: "TOKYO_ZONE", coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), intensity: 0.8, trendingCount: 980, color: .blue, controller: "CYBER_GHOST"),
                        HotZone(name: "DALLAS_HUB", coordinate: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970), intensity: 0.7, trendingCount: 540, color: .green, controller: "VANTAGE_KING"),
                        HotZone(name: "LOND_SECTOR", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), intensity: 0.85, trendingCount: 720, color: .red, controller: "RAZOR_CREW")
                    ]
                    
                    // v3 Strategic Country Takeovers
                    self.countryDominance = [
                        CountryDominance(country: "USA", coordinate: CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129), controller: "VANTAGE_KING", dominanceScore: 0.94, flagEmoji: "🇺🇸"),
                        CountryDominance(country: "JAPAN", coordinate: CLLocationCoordinate2D(latitude: 36.2048, longitude: 138.2529), controller: "CYBER_GHOST", dominanceScore: 0.88, flagEmoji: "🇯🇵"),
                        CountryDominance(country: "UK", coordinate: CLLocationCoordinate2D(latitude: 55.3781, longitude: -3.4360), controller: "RAZOR_CREW", dominanceScore: 0.82, flagEmoji: "🇬🇧")
                    ]
                    
                    // v3 'Own Your Block' Logic (Check if user is top creator in the view)
                    if let userProfile = ProfileManager.shared.currentUser,
                       let userRank = userProfile.dailyRank {
                        // If user is top 10 globally, they are a 'Dominator' in their local block simulation
                        self.isUserBlockOwner = userRank <= 10
                    } else {
                        self.isUserBlockOwner = false
                    }
                } catch {
                    print("Videos RPC Error: \(error)")
                }

                if Task.isCancelled { return }

                // 2. Fetch Active Stories (Safe decoupled fetch to avoid join errors)
                var newStoryMarkers: [WorldMarker] = []
                do {
                    let storyResponse = try await client.database
                        .from("stories")
                        .select("id, latitude, longitude, user_id")
                        .gte("expires_at", value: ISO8601DateFormatter().string(from: Date()))
                        .gte("latitude", value: minLat)
                        .lte("latitude", value: maxLat)
                        .gte("longitude", value: minLong)
                        .lte("longitude", value: maxLong)
                        .execute()
                    
                    if !Task.isCancelled {
                        let rawStories = try decoder.decode([RawStoryMarkerDTO].self, from: storyResponse.data)
                        
                        // Collect unique user IDs to fetch their names
                        let userIds = Array(Set(rawStories.map { $0.user_id.uuidString }))
                        var profiles: [String: String] = [:] // userId -> username
                        
                        if !userIds.isEmpty {
                            let profileResponse = try await client.database
                                .from("profiles")
                                .select("id, username")
                                .in("id", value: userIds)
                                .execute()
                            
                            let profileDTOs = try decoder.decode([MinimalProfileDTO].self, from: profileResponse.data)
                            for p in profileDTOs {
                                profiles[p.id.uuidString] = p.username
                            }
                        }
                        
                        newStoryMarkers = rawStories.map { story in
                            WorldMarker(
                                id: story.id,
                                title: profiles[story.user_id.uuidString] ?? "Story",
                                coordinate: CLLocationCoordinate2D(latitude: story.latitude ?? 0, longitude: story.longitude ?? 0),
                                views: 0,
                                globalRank: nil,
                                neuralScore: nil,
                                isStory: true
                            )
                        }
                    }
                } catch {
                    print("Stories Fetch Error: \(error)")
                }
                
                if Task.isCancelled { return }

                // 3. Pulse Online Friends
                var newFriends: [AppUser] = []
                do {
                    let friendResponse = try await client.database.from("profiles").select().limit(5).execute()
                    newFriends = try decoder.decode([AppUser].self, from: friendResponse.data)
                } catch {
                    print("Friends Fetch Error: \(error)")
                }
                
                if Task.isCancelled { return }

                await MainActor.run {
                    self.worldMarkers = newWorldMarkers
                    self.storyMarkers = newStoryMarkers
                    self.onlineFriends = newFriends
                    // self.topCreators is handled by fetchTopCreators() task below
                    self.isLoading = false
                    
                    // Trigger Top Creators Fetch
                    Task { await self.fetchTopCreators() }
                    
                    // Production: Global Stress Proofing
                    Task {
                        await self.neuralManager.sendNeuralPing(type: "WORLD_PULSE", data: ["region": "global"])
                    }
                }
                
            } catch {
                // Ignore expected cancellation
                if (error as NSError).code == NSURLErrorCancelled { return }
                
                print("Eye World Pulse V2 Primary Error: \(error)")
                await MainActor.run { 
                    self.isLoading = false 
                    self.errorMessage = "NEURAL_PULSE_EXT_ERR"
                }
            }
        }
    }
    
    func searchCreator(query: String) async -> WorldMarker? {
        guard !query.isEmpty else { return nil }
        
        do {
            // Search profiles for the username
            let response = try await client.database
                .from("videos")
                .select("*, author:profiles!author_id(username, avatar_url, follower_count, following_count, xp, monetization_enabled, revenue_cents)")
                .ilike("author.username", value: "%\(query)%")
                .limit(1)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let video = try decoder.decode(EyeWorldVideoDTO.self, from: response.data)
            
            // Return a marker for this video
            return WorldMarker(
                id: video.id,
                title: video.username ?? query,
                coordinate: CLLocationCoordinate2D(
                    latitude: video.latitude ?? 0,
                    longitude: video.longitude ?? 0
                ),
                views: video.views_count ?? 0,
                globalRank: video.global_rank,
                neuralScore: video.neural_score,
                followerCount: video.follower_count,
                followingCount: video.following_count,
                xp: video.xp,
                monetizationEnabled: video.monetization_enabled,
                revenueCents: video.revenue_cents
            )
        } catch {
            print("Creator search error: \(error)")
            return nil
        }
    }
    
    func fetchStoryDetails(id: UUID) async -> AppStory? {
        do {
            let response = try await client.database
                .from("stories")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AppStory.self, from: response.data)
        } catch {
            print("Fetch story details error: \(error)")
            return nil
        }
    }
    
    func fetchTopCreators() async {
        do {
            // Decoupled Fetch: Retrieve stats first, then resolve usernames
            // This bypasses schema relationship errors for DB views
            let response = try await client.database
                .from("top_creators_daily")
                .select("author_id, like_count, view_count, engagement_score, level, xp, daily_rank")
                .order("daily_rank", ascending: true)
                .limit(10)
                .execute()
            
            struct TopCreatorBase: Decodable {
                let author_id: UUID
                let like_count: Int?
                let view_count: Int?
                let engagement_score: Double?
                let level: Int?
                let xp: Int?
                let daily_rank: Int?
            }
            
            let decoder = JSONDecoder()
            let bases = try decoder.decode([TopCreatorBase].self, from: response.data)
            
            let authorIds = bases.map { $0.author_id.uuidString }
            var handles: [String: String] = [:]
            
            if !authorIds.isEmpty {
                let profileResponse = try await client.database
                    .from("profiles")
                    .select("id, username")
                    .in("id", value: authorIds)
                    .execute()
                
                let profileDTOs = try decoder.decode([MinimalProfileDTO].self, from: profileResponse.data)
                for p in profileDTOs {
                    handles[p.id.uuidString] = p.username
                }
            }
            
            await MainActor.run {
                self.topCreators = bases.map { base in
                    TopCreatorDTO(
                        author_id: base.author_id,
                        username: handles[base.author_id.uuidString],
                        like_count: base.like_count,
                        view_count: base.view_count,
                        engagement_score: base.engagement_score,
                        level: base.level,
                        xp: base.xp,
                        daily_rank: base.daily_rank
                    )
                }
                self.errorMessage = nil
            }
        } catch {
            print("Leaderboard Fetch Error: \(error)")
        }
    }
}

