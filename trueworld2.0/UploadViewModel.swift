import Combine
import Supabase
import SwiftUI
import PhotosUI
import CoreLocation
import Realtime
internal import _Helpers



@MainActor
class UploadViewModel: ObservableObject {
    
    @Published var selectedItem: PhotosPickerItem?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var videoDescription = ""
    @Published var musicTitle = "Original Sound"
    @Published var errorMessage: String?
    @Published var uploadSuccess = false
    
    // Stories v2.0
    @Published var isPostAsStory = false
    @Published var isLockedStory = false
    @Published var storyPrice: Double = 0.0
    
    // Geolocation
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var locationName: String? = nil
    @Published var isLocating = false
    @Published var isPrivacyGuardEnabled = true // AI Location Safety
    private let locationManager = LocationManager.shared
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        locationManager.$location
            .receive(on: RunLoop.main)
            .sink { [weak self] loc in
                if let loc = loc {
                    self?.latitude = loc.coordinate.latitude
                    self?.longitude = loc.coordinate.longitude
                    self?.isLocating = false
                    self?.reverseGeocode(loc)
                }
            }
            .store(in: &cancellables)
    }
    
    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                
                DispatchQueue.main.async {
                    if !city.isEmpty && !state.isEmpty {
                        self?.locationName = "\(city), \(state)"
                    } else if !city.isEmpty {
                        self?.locationName = city
                    } else {
                        self?.locationName = country
                    }
                }
            }
        }
    }
    
    func requestLocation() {
        isLocating = true
        locationManager.requestPermission()
        locationManager.startUpdating()
        
        // Ensure privacy setting is in sync
        locationManager.isPrivacyModeEnabled = isPrivacyGuardEnabled
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.isLocating = false
        }
    }
    


    func uploadMedia() async {
        guard let selectedItem = selectedItem else {
            errorMessage = "Please select media first"
            return
        }
        
        isUploading = true
        ProfileManager.shared.isUploading = true
        errorMessage = nil
        uploadProgress = 0.1
        
        do {
            let client = SupabaseManager.shared.client
            let user = try await client.auth.session.user
            
            // 1. Load Data
            guard let mediaData = try await selectedItem.loadTransferable(type: Data.self) else {
                throw NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to load media data"])
            }
            
            // Determine content type (basic check)
            let isVideo = selectedItem.supportedContentTypes.contains(where: { $0.conforms(to: .video) })
            let contentType = isVideo ? "video/mp4" : "image/jpeg"
            let ext = isVideo ? "mp4" : "jpg"
            
            uploadProgress = 0.3
            
            // 2. Upload to Storage
            let bucket = isPostAsStory ? "stories" : "videos"
            let fileName = "\(user.id)/\(UUID().uuidString).\(ext)"
            
            try await client.storage
                .from(bucket)
                .upload(path: fileName, file: mediaData, options: FileOptions(contentType: contentType))
            
            uploadProgress = 0.7
            
            // 3. Get Public URL
            let publicURL = try client.storage.from(bucket).getPublicURL(path: fileName)
            
            // 4. Persistence
            locationManager.isPrivacyModeEnabled = isPrivacyGuardEnabled
            let protectedLoc = locationManager.protectedLocation
            
                if isPostAsStory {
                    // v3 Neural Longevity: Top Creators get 48h, everyone else 24h
                    let isTopCreator = ProfileManager.shared.currentUser?.isVerified == true || ProfileManager.shared.currentUser?.isRisingStar == true
                    let duration: TimeInterval = isTopCreator ? (48 * 3600) : (24 * 3600)
                    let expirationDate = Date().addingTimeInterval(duration)
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let expirationStr = isoFormatter.string(from: expirationDate)
                    
                    let storyPayload = StoryInsert(
                        userId: user.id,
                        mediaUrl: publicURL.absoluteString,
                        mediaType: isVideo ? "video" : "image",
                        isLocked: isLockedStory,
                        price: storyPrice,
                        latitude: protectedLoc?.coordinate.latitude,
                        longitude: protectedLoc?.coordinate.longitude,
                        isLocationProtected: isPrivacyGuardEnabled ? true : nil,
                        expiresAt: expirationStr
                    )

                    try await client.database
                        .from("stories")
                        .insert(storyPayload)
                        .execute()
                } else {
                locationManager.isPrivacyModeEnabled = isPrivacyGuardEnabled
                let protectedLoc = locationManager.protectedLocation
                
                let payload = VideoInsertDTO(
                    video_url: publicURL.absoluteString,
                    username: "@\(user.email?.components(separatedBy: "@").first ?? "user")",
                    description: videoDescription,
                    music_title: musicTitle,
                    likes: 0,
                    comments: 0,
                    shares: 0,
                    author_id: user.id,
                    latitude: protectedLoc?.coordinate.latitude,
                    longitude: protectedLoc?.coordinate.longitude,
                    is_location_protected: isPrivacyGuardEnabled
                )
                
                try await client.database
                    .from("videos")
                    .insert(payload)
                    .execute()
            }
            
            uploadProgress = 1.0
            uploadSuccess = true
            
        } catch {
            print("Upload Error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isUploading = false
        ProfileManager.shared.isUploading = false
    }
    
    func reset() {
        selectedItem = nil
        videoDescription = ""
        musicTitle = "Original Sound"
        uploadSuccess = false
        errorMessage = nil
        uploadProgress = 0
        isPostAsStory = false
        isLockedStory = false
        storyPrice = 0.0
        latitude = nil
        longitude = nil
        locationName = nil
    }
}

