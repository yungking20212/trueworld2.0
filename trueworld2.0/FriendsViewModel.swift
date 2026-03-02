import Foundation
import Supabase
import SwiftUI
import Combine
import Realtime

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var suggestedUsers: [AppUser] = []
    @Published var followingUsers: [AppUser] = []
    @Published var followersUsers: [AppUser] = []
    @Published var trendingCreators: [AppUser] = []
    
    @Published var followingIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var searchQuery = ""
    @Published var searchResults: [AppUser] = []
    
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannel?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearch()
    }
    
    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if !query.isEmpty {
                    Task { await self?.performSearch(query) }
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchSocialHub() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await client.auth.session.user
            setupRealtimeSubscription(userId: user.id)
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchSuggested() }
                group.addTask { await self.fetchFollowing() }
                group.addTask { await self.fetchFollowers() }
            }
        } catch {
            print("Error in fetchSocialHub: \(error)")
        }
        
        isLoading = false
    }
    
    private func setupRealtimeSubscription(userId: UUID) {
        guard channel == nil else { return }
        
        let channel = client.realtime.channel("public:follows")
        self.channel = channel
        
        channel.on("postgres_changes", filter: ChannelFilter(event: "*", schema: "public", table: "follows")) { [weak self] message in
            Task { [weak self] in
                // Real-time social change detected
                await self?.refreshSocialData()
            }
        }
        
        channel.subscribe()
    }
    
    private func refreshSocialData() async {
        let query = searchQuery
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchFollowing() }
            group.addTask { await self.fetchFollowers() }
            group.addTask { await self.fetchSuggested() }
            if !query.isEmpty {
                group.addTask { await self.performSearch(query) }
            }
        }
    }
    
    private func fetchSuggested() async {
        do {
            let user = try await client.auth.session.user
            
            let response = try await client
                .database
                .from("profiles")
                .select()
                .neq("id", value: user.id)
                .limit(20)
                .execute()
            
            let decoder = JSONDecoder()
            let fetchedDTOs = try decoder.decode([AppProfileDTO].self, from: response.data)
            
            let users = fetchedDTOs.map { mapDTOToUser($0) }
            self.suggestedUsers = users
            
            // Trending = High XP or high follower count
            self.trendingCreators = users.filter { $0.xp > 500 || $0.followerCount > 50 }
                .sorted(by: { $0.xp > $1.xp })
            
            if self.trendingCreators.isEmpty {
                self.trendingCreators = Array(users.prefix(5))
            }
        } catch {
            print("Error fetching suggested: \(error)")
        }
    }
    
    private func fetchFollowing() async {
        do {
            let user = try await client.auth.session.user
            
            let response = try await client
                .database
                .from("follows")
                .select("following_id, profiles!following_id(*)")
                .eq("follower_id", value: user.id)
                .execute()
            
            let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
            var users: [AppUser] = []
            
            for item in data {
                if let profileDict = item["profiles"] as? [String: Any] {
                    let profileData = try JSONSerialization.data(withJSONObject: profileDict)
                    let dto = try JSONDecoder().decode(AppProfileDTO.self, from: profileData)
                    users.append(mapDTOToUser(dto))
                }
            }
            
            self.followingUsers = users
            self.followingIds = Set(users.map { $0.id })
        } catch {
            print("Error fetching following: \(error)")
        }
    }
    
    private func fetchFollowers() async {
        do {
            let user = try await client.auth.session.user
            
            let response = try await client
                .database
                .from("follows")
                .select("follower_id, profiles!follower_id(*)")
                .eq("following_id", value: user.id)
                .execute()
            
            let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
            var users: [AppUser] = []
            
            for item in data {
                if let profileDict = item["profiles"] as? [String: Any] {
                    let profileData = try JSONSerialization.data(withJSONObject: profileDict)
                    let dto = try JSONDecoder().decode(AppProfileDTO.self, from: profileData)
                    users.append(mapDTOToUser(dto))
                }
            }
            
            self.followersUsers = users
        } catch {
            print("Error fetching followers: \(error)")
        }
    }
    
    private func performSearch(_ query: String) async {
        do {
            let response = try await client
                .database
                .from("profiles")
                .select()
                .or("username.ilike.%\(query)%,full_name.ilike.%\(query)%")
                .order("follower_count", ascending: false)
                .limit(20)
                .execute()
            
            let dtos = try JSONDecoder().decode([AppProfileDTO].self, from: response.data)
            self.searchResults = dtos.map { mapDTOToUser($0) }
        } catch {
            print("Search error: \(error)")
        }
    }
    
    func toggleFollow(for userId: UUID) async {
        if followingIds.contains(userId) {
            await unfollowUser(userId)
        } else {
            await followUser(userId)
        }
    }
    
    private func followUser(_ userId: UUID) async {
        do {
            let currentUser = try await client.auth.session.user
            
            try await client.database
                .from("follows")
                .insert([
                    "follower_id": currentUser.id.uuidString,
                    "following_id": userId.uuidString
                ])
                .execute()
            
            // snappiness
            followingIds.insert(userId)
        } catch {
            print("Error following user: \(error)")
        }
    }
    
    func sendNeuralPing(to userId: UUID) async {
        do {
            let currentUser = try await client.auth.session.user
            
            // Insert notification directly
            try await client.database
                .from("notifications")
                .insert([
                    "user_id": userId.uuidString,
                    "actor_id": currentUser.id.uuidString,
                    "type": "neural_ping",
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            // Haptic Feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        } catch {
            print("Error sending Neural Ping: \(error)")
        }
    }
    
    private func unfollowUser(_ userId: UUID) async {
        do {
            let currentUser = try await client.auth.session.user
            
            try await client.database
                .from("follows")
                .delete()
                .eq("follower_id", value: currentUser.id)
                .eq("following_id", value: userId)
                .execute()
            
            // snappiness
            followingIds.remove(userId)
        } catch {
            print("Error unfollowing user: \(error)")
        }
    }
    
    private func mapDTOToUser(_ dto: AppProfileDTO) -> AppUser {
        AppUser(
            id: dto.id,
            username: dto.username,
            fullName: dto.fullName,
            avatarURL: dto.avatarURL,
            bio: dto.bio,
            isPrivate: dto.isPrivate,
            followerCount: dto.followerCount,
            followingCount: dto.followingCount,
            xp: dto.xp ?? 0,
            monetizationEnabled: dto.monetization_enabled ?? false,
            revenueCents: dto.revenue_cents ?? 0
        )
    }
    
    deinit {
        channel?.unsubscribe()
    }
}

