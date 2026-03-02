//
//  ContentView.swift
//  trueworld2.0
//
//  Created by Kendall Gipson on 2/24/26.
//

import SwiftUI
import Auth
import Supabase

struct ContentView: View {
    @State private var session: Session?
    @State private var selectedTab = 0
    @State private var isProfileComplete: Bool? = nil
    @StateObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var uiState = AppGlobalUIState.shared
    @Namespace private var navNamespace
    
    var body: some View {
        Group {
            if session != nil {
                mainAppView
                    .ignoresSafeArea()
                    .background(Color.black)
                    .overlay(alignment: .bottom) {
                        if !uiState.isTabBarHidden {
                            // Custom Glassmorphic Tab Bar
                            HStack(spacing: 0) {
                                TabButton(index: 0, icon: "house.fill", label: "Home", selectedTab: $selectedTab, namespace: navNamespace)
                                TabButton(index: 1, icon: "globe.americas.fill", label: "World", selectedTab: $selectedTab, namespace: navNamespace)
                                TabButton(index: 6, icon: "sparkles.tv.fill", label: "Studio", selectedTab: $selectedTab, namespace: navNamespace, isSpecial: true)
                                
                                // Center Add Button
                                VStack {
                                    Button(action: { 
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedTab = 3 
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(AppDesignSystem.Colors.primaryGradient)
                                                .frame(width: 48, height: 48)
                                                .shadow(color: Color(hex: "FF0080").opacity(0.3), radius: 12, y: 6)
                                            
                                            Image(systemName: "plus")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .offset(y: -4)
                                }
                                .frame(maxWidth: .infinity)
                                
                                TabButton(index: 2, icon: "bell.fill", label: "Activity", selectedTab: $selectedTab, namespace: navNamespace, badgeCount: notificationManager.unreadCount)
                                TabButton(index: 4, icon: "text.bubble.fill", label: "Inbox", selectedTab: $selectedTab, namespace: navNamespace)
                                TabButton(index: 5, icon: "person.fill", label: "Profile", selectedTab: $selectedTab, namespace: navNamespace, avatarURL: ProfileManager.shared.currentUser?.avatarURL, isUploading: ProfileManager.shared.isUploading)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .cornerRadius(30)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .overlay {
                        // In-App Notification Banner Overlay
                        if notificationManager.showBanner, let notification = notificationManager.latestNotification {
                            VStack {
                                InAppNotificationBanner(notification: notification) {
                                    withAnimation {
                                        notificationManager.showBanner = false
                                    }
                                }
                                .padding(.top, 60)
                                Spacer()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(100)
                        }
                    }
                    .ignoresSafeArea(.keyboard)
                    .fullScreenCover(isPresented: Binding(
                        get: { session != nil && isProfileComplete == false },
                        set: { _ in }
                    )) {
                        OnboardingView()
                            .onDisappear {
                                // Re-check after onboarding
                                Task { await checkProfileCompletion() }
                            }
                    }
            } else {
                AuthView()
            }
        }
        .task {
            // Check current session
            self.session = try? await SupabaseManager.shared.client.auth.session
            if session != nil {
                await checkProfileCompletion()
                await NotificationManager.shared.requestPermission()
            }
            
            // Listen for auth state changes
            for await (event, session) in await SupabaseManager.shared.client.auth.authStateChanges {
                print("Auth Event: \(event)")
                withAnimation {
                    self.session = session
                }
                if session != nil {
                    await checkProfileCompletion()
                    await NotificationManager.shared.requestPermission()
                }
            }
        }
    }
    
    private func checkProfileCompletion() async {
        guard let userId = session?.user.id else { return }
        
        do {
            let response = try await SupabaseManager.shared.client.database
                .from("profiles")
                .select("username")
                .eq("id", value: userId)
                .single()
                .execute()
            
            // If we have a username, profile is "complete" for now
            let data = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            let username = data?["username"] as? String
            isProfileComplete = username != nil && !username!.isEmpty
        } catch {
            // If profile doesn't exist, it's not complete
            isProfileComplete = false
        }
    }
    
    @ViewBuilder
    private var mainAppView: some View {
        switch selectedTab {
        case 0:
            VideoFeedView()
        case 1:
            EyeWorldView()
        case 2:
            NotificationsView()
        case 3:
            UploadView()
        case 4:
            InboxView()
        case 5:
            ProfileView()
        case 6:
            AIProductionView()
        default:
            VideoFeedView()
        }
    }
}

struct TabButton: View {
    let index: Int
    let icon: String
    let label: String
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    var badgeCount: Int = 0
    var isSpecial: Bool = false
    var avatarURL: URL? = nil
    var isUploading: Bool = false
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if let url = avatarURL {
                        AppAvatar(url: url, size: 24, isUploading: isUploading)
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: selectedTab == index ? .bold : .medium))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.3))
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                    }
                    
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -8)
                            .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1).offset(x: 10, y: -8))
                            .transition(.scale)
                    }
                    
                    if isSpecial {
                        Text("AI")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(AppDesignSystem.Colors.primaryGradient)
                            .cornerRadius(4)
                            .offset(x: 12, y: -10)
                    }
                }
                
                // Animated selected indicator (Premium bar style)
                ZStack {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 20, height: 3)
                    
                    if selectedTab == index {
                        Capsule()
                            .fill(index == 0 ? AnyShapeStyle(Color.white) : AnyShapeStyle(AppDesignSystem.Colors.primaryGradient))
                            .frame(width: 20, height: 3)
                            .matchedGeometryEffect(id: "nav_tab_underline", in: namespace)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

struct PlaceholderScreen: View {
    let title: String
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    ContentView()
}
