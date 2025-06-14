import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift // For Codable support with Firestore
import FirebaseStorage
import FirebaseAuth // To get current user UID

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    // Fields bound to UI, initialized from userProfile
    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var locationSharingEnabled: Bool = true
    @Published var photoItems: [String] = [] // Stores URLs of photos or local identifiers for upload

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var saveSuccess: Bool = false


    private var db = Firestore.firestore()
    // private var storage = Storage.storage() // Uncomment if actual uploads are implemented
    private var currentUserID: String? { Auth.auth().currentUser?.uid }

    private var cancellables = Set<AnyCancellable>() // Corrected var name
    private var locationService: LocationService? // To be injected or received from environment

    // init() called by @StateObject or @ObservedObject
    // If locationService is passed via environment, it won't be available in init directly
    // unless this ViewModel is also an EnvironmentObject or receives it as a parameter.
    // For now, let's assume it will be set up after init.
    // A better pattern might be to pass LocationService in init.
    // init(locationService: LocationService) {
    //    self.locationService = locationService
    //    // ... existing init logic ...
    // }

    init() {
        // Combine pipeline to react to userProfile changes and update bound fields
        $userProfile
            .receive(on: RunLoop.main)
            .sink { [weak self] profile in
                guard let self = self, let profile = profile else { return }
                self.username = profile.username
                self.bio = profile.bio ?? ""
                self.locationSharingEnabled = profile.locationSharingEnabled
                self.photoItems = profile.photoURLs ?? []
            }
            .store(in: &cancellables)

        // fetchUserProfile() // Call fetchUserProfile when currentUserID is known, e.g. onAppear or when auth state changes.
                           // Or if locationService is passed in init:
                           // self.locationService = locationService
                           // fetchUserProfile()
    }

    // Call this method when the ViewModel appears or when the LocationService becomes available.
    func setup(locationService: LocationService) {
        self.locationService = locationService
        // Now that locationService is available, we can fetch the profile
        // and then update location service with profile settings.
        if userProfile == nil { // Fetch only if not already loaded
             fetchUserProfile()
        } else {
             // If profile is already loaded (e.g. from a cache or previous fetch),
             // still update locationService with current settings.
             self.locationService?.updateUserProfileSettings(self.userProfile)
        }

        // Listen for app lifecycle notifications to manage locationService
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.locationService?.appDidEnterForeground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.locationService?.appDidEnterBackground() }
            .store(in: &cancellables)
    }


    func fetchUserProfile() {
        guard let userID = currentUserID else {
            errorMessage = "User not logged in."
            // Potentially stop location updates if user logs out.
            // locationService?.updateUserProfileSettings(nil) // This would stop it.
            return
        }
        isLoading = true
        db.collection("users").document(userID).getDocument { [weak self] documentSnapshot, error in
            // Defer is not needed here as isLoading is set at start and end of relevant blocks
            if let error = error {
                self?.isLoading = false
                self?.errorMessage = "Error fetching profile: \(error.localizedDescription)"
                return
            }
            guard let document = documentSnapshot, document.exists else {
                self?.isLoading = false
                // This case might mean a new user whose profile wasn't created yet by signup logic.
                // Or, an actual error. For now, treat as an error or missing profile.
                // Consider creating a default profile here if that's the desired flow.
                self?.errorMessage = "Profile document does not exist. Please complete signup or contact support."
                // No profile, so location sharing is effectively off for this non-existent user.
                // Update location service with nil profile to stop any potential updates.
                self?.locationService?.updateUserProfileSettings(nil)
                return
            }
            do {
                let fetchedProfile = try document.data(as: UserProfile.self)
                self?.userProfile = fetchedProfile
                // The sink for $userProfile will update other @Published properties (username, bio, etc.)
                self?.errorMessage = nil
                // After fetching profile, update LocationService with the settings
                self?.locationService?.updateUserProfileSettings(fetchedProfile)
            } catch {
                self?.errorMessage = "Error decoding profile: \(error.localizedDescription)"
                self?.locationService?.updateUserProfileSettings(nil) // Stop on error
            }
            self?.isLoading = false // Ensure isLoading is set to false in all paths
        }
    }

    func saveProfile() {
        guard let userID = currentUserID else {
            errorMessage = "User not logged in or profile not loaded."
            return
        }
        isLoading = true
        saveSuccess = false // Reset save success status

        // Create a dictionary for updates to only send changed values if preferred,
        // or update the local userProfile object and set it entirely.
        // For simplicity with Codable, updating the local userProfile object and re-setting it is easier.

        var profileToUpdate = self.userProfile ?? UserProfile(id: userID, username: self.username) // Create new if nil (shouldn't happen if fetch worked)

        profileToUpdate.username = username
        profileToUpdate.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
        profileToUpdate.locationSharingEnabled = locationSharingEnabled
        profileToUpdate.photoURLs = photoItems // Assumes photoItems holds the final URLs
        profileToUpdate.updatedAt = Timestamp(date: Date()) // Firestore server timestamp preferred, but client can set for optimistic UI

        do {
            // Using merge: true to only update fields present in the model, good for partial updates
            // or if the model might not have all fields (e.g. createdAt).
            // If UserProfile is complete, merge: false (the default) would overwrite the document.
            // Given we fetch then update, merge: true is safer.
            try db.collection("users").document(userID).setData(from: profileToUpdate, merge: true) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error saving profile: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.saveSuccess = true
                    self.userProfile = profileToUpdate // Update local cache
                    print("Profile saved successfully.")
                    // After saving, especially if locationSharingEnabled changed, update LocationService
                    self.locationService?.updateUserProfileSettings(profileToUpdate)
                }
            }
        } catch {
            self.isLoading = false
            self.errorMessage = "Error encoding profile for save: \(error.localizedDescription)"
        }
    }

    // Expose a way to request location permission if needed from UI,
    // though LocationService tries to handle it internally.
    func requestLocationPermissionIfNeeded() {
        locationService?.requestPermission()
    }

    func addPhoto(placeholderURL: String) {
        if photoItems.count < 7 {
            photoItems.append(placeholderURL)
            // In a real app: trigger image picker, upload, get URL, then add.
        } else {
            errorMessage = "Maximum of 7 photos allowed."
        }
    }

    func removePhoto(at offsets: IndexSet) {
        photoItems.remove(atOffsets: offsets)
        // In a real app: if URLs point to Firebase Storage, also delete the file from Storage.
    }
}
