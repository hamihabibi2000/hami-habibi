import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private var currentUserID: String? { Auth.auth().currentUser?.uid }

    @Published var lastKnownLocation: CLLocation?
    @Published var permissionStatus: CLAuthorizationStatus
    @Published var locationError: Error?

    private var userProfileSettings: UserProfile? // Local cache of user's location sharing preference

    override init() {
        self.permissionStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Balance accuracy and power
        // locationManager.distanceFilter = 500 // meters; update if moved by this much (optional)
         print("LocationService initialized. Current status: \(permissionStatus.rawValue)")
    }

    // Public method to be called when user profile data (especially locationSharingEnabled) is available or changes.
    public func updateUserProfileSettings(_ profile: UserProfile?) {
        self.userProfileSettings = profile
        print("LocationService: User profile settings updated. Sharing enabled: \(profile?.locationSharingEnabled ?? false)")
        // After settings update, re-evaluate if location services should be active.
        evaluateLocationNeeds()
    }

    private func evaluateLocationNeeds() {
        guard let settings = userProfileSettings else {
            print("LocationService: No user profile settings, stopping updates.")
            stopUpdatingLocation()
            return
        }

        if settings.locationSharingEnabled {
            print("LocationService: Sharing enabled in settings. Current permission: \(permissionStatus.rawValue)")
            // If permission is already granted, start updates. Otherwise, it will start if/when permission is granted via delegate.
            if permissionStatus == .authorizedWhenInUse || permissionStatus == .authorizedAlways {
                startUpdatingLocationInternal()
            } else if permissionStatus == .notDetermined {
                requestPermission() // Request if not yet determined
            } else {
                print("LocationService: Permission not sufficient (\(permissionStatus.rawValue)), stopping updates.")
                stopUpdatingLocation() // Stop if no longer permitted
            }
        } else {
            print("LocationService: Sharing disabled in settings, stopping updates.")
            stopUpdatingLocation()
        }
    }

    func requestPermission() {
        if permissionStatus == .notDetermined {
            print("LocationService: Requesting When In Use authorization.")
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // Internal method to start location updates, assumes checks are done.
    private func startUpdatingLocationInternal() {
        print("LocationService: Starting location updates (internal call).")
        locationManager.startUpdatingLocation()
        // locationManager.startMonitoringSignificantLocationChanges() // Alternative for less frequent updates
    }

    // Public method that could be called on app foregrounding, for example
    public func appDidEnterForeground() {
        print("LocationService: App entered foreground. Re-evaluating location needs.")
        // Re-check permission status as it could have changed in system settings
        self.permissionStatus = locationManager.authorizationStatus
        evaluateLocationNeeds()
    }

    public func appDidEnterBackground() {
        print("LocationService: App entered background.")
        // Decide if location updates should continue based on app logic (e.g., only if .authorizedAlways)
        // For "When In Use", system typically handles stopping/starting.
        // If using significant location changes, it might continue.
        // For now, simple stop for "When In Use" or if only foreground updates are desired.
        // locationManager.stopUpdatingLocation() // Or more nuanced logic
    }


    func stopUpdatingLocation() {
        print("LocationService: Stopping location updates.")
        locationManager.stopUpdatingLocation()
        // locationManager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate methods

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("LocationService: Authorization changed to: \(manager.authorizationStatus.rawValue)")
        // Update published status
        DispatchQueue.main.async { // Ensure UI updates on main thread if this directly drives UI
            self.permissionStatus = manager.authorizationStatus
        }
        // Re-evaluate location needs based on new permission status
        evaluateLocationNeeds()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.lastKnownLocation = location
            self.locationError = nil
        }
        print("LocationService: Location updated: \(location.coordinate)")

        if let settings = self.userProfileSettings, settings.locationSharingEnabled, let userID = currentUserID {
            updateLocationInFirestore(userID: userID, location: location)
        } else {
            print("LocationService: Location sharing disabled or user/profile not set. Not updating Firestore.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: Failed to get location: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.locationError = error
        }
        // Consider stopping updates if it's a fatal error, e.g. kCLErrorDenied
        if let clError = error as? CLError, clError.code == .denied {
            stopUpdatingLocation()
        }
    }

    private func updateLocationInFirestore(userID: String, location: CLLocation) {
        let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let data: [String: Any] = [
            "lastKnownLocation": geoPoint,
            "updatedAt": Timestamp(date: Date()) // Or FieldValue.serverTimestamp() if preferred
        ]
        db.collection("users").document(userID).updateData(data) { error in
            if let error = error {
                print("LocationService: Error updating location in Firestore: \(error.localizedDescription)")
            } else {
                print("LocationService: User location updated in Firestore.")
            }
        }
    }
}
