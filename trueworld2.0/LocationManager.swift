import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isPrivacyModeEnabled: Bool = true // Default to safe mode
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 
    }
    
    // AI Privacy: Snap to a 500m-1km safe grid or add random jitter
    var protectedLocation: CLLocation? {
        guard let original = location else { return nil }
        if !isPrivacyModeEnabled { return original }
        
        // Snapping logic: Reduce precision to ~1km (2 decimal places)
        let lat = (original.coordinate.latitude * 100).rounded() / 100
        let long = (original.coordinate.longitude * 100).rounded() / 100
        
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long),
            altitude: original.altitude,
            horizontalAccuracy: 1000, // Reduced accuracy
            verticalAccuracy: original.verticalAccuracy,
            timestamp: original.timestamp
        )
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
}
