import SwiftUI
import Supabase

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppDesignSystem.Components.DynamicBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header v2.0
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Neural Settings")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        Spacer()
                        
                        // Action Placeholder
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            // Search Bar v1.0 Production
                            searchBar
                            
                            // Hero Profile v2.0: Neural Stats
                            heroSection
                            
                            // 1. Account & Identity
                            SettingsSection(title: "Account & Identity") {
                                NavigationLink(destination: EditProfileView(viewModel: EditProfileViewModel(user: viewModel.userProfile ?? AppUser(id: UUID(), username: nil, fullName: nil, avatarURL: nil, bio: nil)))) {
                                    SettingsRow(icon: "person.crop.circle.fill", title: "Personal Information", subtitle: "Manage your global handle & bio")
                                }
                                
                                NavigationLink(destination: NotificationSettingsView(viewModel: viewModel)) {
                                    SettingsRow(icon: "bell.badge.fill", title: "Notifications", subtitle: "Configure push & activity pings")
                                }
                            }
                            
                            // 2. Monetization (Creator Portal)
                            SettingsSection(title: "Creator Ecosystem") {
                                monetizationToggleRow
                                
                                storyAiMonetizationSection
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 56)
                                
                                Button(action: {
                                    Task { await viewModel.linkBank() }
                                }) {
                                    SettingsRow(
                                        icon: "building.columns.circle.fill",
                                        title: "Financial Integration",
                                        subtitle: viewModel.userProfile?.payoutStatus == "active" ? "STRIPE CONNECTED" : "UNLINKED",
                                        statusColor: viewModel.userProfile?.payoutStatus == "active" ? .cyan : .orange,
                                        showChevron: true
                                    )
                                }
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 56)
                                
                                NavigationLink(destination: TransactionHistoryView(viewModel: viewModel)) {
                                    SettingsRow(icon: "clock.arrow.circlepath", title: "Payout History", subtitle: "Audit your withdrawal logs")
                                }
                                
                                NavigationLink(destination: CreatorAnalyticsView(viewModel: viewModel)) {
                                    SettingsRow(
                                        icon: "chart.xyaxis.line",
                                        title: "Neural Analytics",
                                        subtitle: "Track your 20X Story AI performance",
                                        iconColor: .purple
                                    )
                                }
                                
                                if viewModel.userProfile?.monetizationEnabled == true {
                                    Divider().background(Color.white.opacity(0.1)).padding(.leading, 56)
                                    earningsCard
                                }
                            }
                            
                            // 3. Privacy & Safety
                            SettingsSection(title: "Privacy & Neural Safety") {
                                NavigationLink(destination: PrivacySettingsView(viewModel: viewModel)) {
                                    SettingsRow(icon: "lock.shield.fill", title: "Privacy Control", subtitle: "Cloakin, Visibility & Blocking", iconColor: .cyan)
                                }
                                
                                NavigationLink(destination: ReportProblemView()) {
                                    SettingsRow(icon: "exclamationmark.bubble.fill", title: "Report a Disturbance", subtitle: "Flag bugs or community violations", iconColor: .orange)
                                }
                            }
                            
                            // 4. Support & Legal
                            SettingsSection(title: "Support Hub") {
                                NavigationLink(destination: SupportView()) {
                                    SettingsRow(icon: "lifepreserver.fill", title: "Neural Help Center", subtitle: "Guides, FAQS & Direct Support")
                                }
                                
                                NavigationLink(destination: TermsOfServiceView()) {
                                    SettingsRow(icon: "doc.text.magnifyingglass", title: "Terms of Service", subtitle: "V2.0 Core Protocols")
                                }
                                
                                NavigationLink(destination: PrivacyPolicyView()) {
                                    SettingsRow(icon: "shield.lefthalf.filled", title: "Privacy Policy", subtitle: "How your pings are processed")
                                }
                            }
                            
                            // 5. Authentication
                            logoutButton
                            
                            VStack(spacing: 4) {
                                Text("Trueworld 2.0")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Production Build v2.0.4")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.top, 10)
                        }
                        .padding(.bottom, 40)
                    }
                }
                
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingOnboarding) {
                if let url = viewModel.onboardingURL {
                    StripeOnboardingView(url: url)
                }
            }
        }
    }
    
    // MARK: - Components v2.0
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
            TextField("Search Protocols...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 20)
    }
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                AppAvatar(url: viewModel.userProfile?.avatarURL, size: 70)
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userProfile?.fullName ?? "Ghost User")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("@\(viewModel.userProfile?.username ?? "unknown")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                }
                
                Spacer()
                
                // Level Badge
                VStack(spacing: 2) {
                    Text("LEVEL")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.cyan)
                    Text("\(viewModel.userProfile?.level ?? 1)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            
            // Stats Bar
            HStack {
                statItem(label: "Followers", value: "\(viewModel.userProfile?.followerCount ?? 0)")
                Divider().frame(height: 20).background(Color.white.opacity(0.1))
                statItem(label: "Following", value: "\(viewModel.userProfile?.followingCount ?? 0)")
                Divider().frame(height: 20).background(Color.white.opacity(0.1))
                statItem(label: "Neural XP", value: "\(viewModel.userProfile?.xp ?? 0)")
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(24)
        .background(.ultraThinMaterial.opacity(0.2))
        .cornerRadius(28)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 20)
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var monetizationToggleRow: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.green.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Monetization Status")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(viewModel.userProfile?.monetizationEnabled == true ? "ELIGIBLE / ACTIVE" : "INACTIVE")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(viewModel.userProfile?.monetizationEnabled == true ? .green : .white.opacity(0.3))
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { viewModel.userProfile?.monetizationEnabled ?? false },
                set: { newValue in
                    Task {
                        await viewModel.toggleMonetization(enabled: newValue)
                    }
                }
            ))
            .tint(.green)
            .labelsHidden()
        }
        .padding(20)
    }
    
    private var storyAiMonetizationSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.purple)
                        Text("STORY AI MONETIZING")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    
                    Text("REVENUE MULTIPLIER")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(viewModel.userProfile?.storyAiMonetizationEnabled == true ? "20X" : "1.0X")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 10)
            }
            
            Text("AI-driven neural ad placement for Story Mode. Earn 20x more than standard video broadcasts.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
            
            Toggle("", isOn: Binding(
                get: { viewModel.userProfile?.storyAiMonetizationEnabled ?? false },
                set: { newValue in
                    Task {
                        await viewModel.toggleStoryAiMonetization(enabled: newValue)
                    }
                }
            ))
            .tint(.purple)
            .labelsHidden()
            .scaleEffect(1.2)
            
            VStack(alignment: .leading, spacing: 8) {
                Divider().background(Color.white.opacity(0.1))
                
                HStack(spacing: 12) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("USERS ARE MAKING 20X MORE")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 4)
                
                Text("Stories trigger high-intent neural ad-placements which pay out significantly more than traditional video broadcasts.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    viewModel.userProfile?.storyAiMonetizationEnabled == true ? 
                    AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)) : 
                    AnyShapeStyle(Color.white.opacity(0.1)),
                    lineWidth: 1
                )
        )
    }
    
    

    private var earningsCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NEURAL REVENUE")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.cyan)
                    .tracking(1)
                
                Text("$\(Double(viewModel.userProfile?.revenueCents ?? 0) / 100.0, specifier: "%.2f")")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                if viewModel.userProfile?.payoutStatus == "active", let bank = viewModel.userProfile?.bankName, let last4 = viewModel.userProfile?.bankLast4 {
                    HStack(spacing: 4) {
                        Image(systemName: "building.columns.fill")
                        Text("\(bank) •••• \(last4)")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            Button(action: {
                if viewModel.userProfile?.payoutStatus == "active" {
                    Task { await viewModel.withdrawFunds() }
                } else {
                    Task { await viewModel.linkBank() }
                }
            }) {
                Text(viewModel.userProfile?.payoutStatus == "active" ? "Withdraw" : "Link Wallet")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(viewModel.userProfile?.payoutStatus == "active" ? AnyView(AppDesignSystem.Colors.primaryGradient) : AnyView(Color.white.opacity(0.1)))
                    .cornerRadius(12)
                    .shadow(color: viewModel.userProfile?.payoutStatus == "active" ? .cyan.opacity(0.3) : .clear, radius: 10)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .padding(10)
    }
    
    private var logoutButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await viewModel.signOut()
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18, weight: .bold))
                    Text("Log Out of Neural Net")
                        .font(.system(size: 16, weight: .black))
                }
                .foregroundColor(.pink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.2), lineWidth: 1))
            }
            .padding(.horizontal, 20)
            
            Button(action: { showingDeleteConfirmation = true }) {
                Text("Delete Identity & All Neural Data")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.vertical, 10)
            }
        }
        .padding(.top, 10)
        .alert("Purge Neural Identity?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Purge Forever", role: .destructive) {
                Task {
                    if await viewModel.deleteAccount() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This action is irreversible. All your broadcasts, revenue logs, and neural presence will be permanently erased from the Trueworld network.")
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView()
                    .tint(.cyan)
                    .scaleEffect(1.5)
                
                Text("SYNCHRONIZING WITH CORE...")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(3)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(32)
            .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// MARK: - Reusable V2 UI Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1.5)
                .padding(.leading, 24)
            
            VStack(spacing: 0) {
                content
            }
            .background(.ultraThinMaterial.opacity(0.4))
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let statusColor: Color?
    let showChevron: Bool
    
    init(icon: String, title: String, subtitle: String? = nil, iconColor: Color = .white, statusColor: Color? = nil, showChevron: Bool = true) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.statusColor = statusColor
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(iconColor.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(statusColor ?? .white.opacity(0.4))
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}
