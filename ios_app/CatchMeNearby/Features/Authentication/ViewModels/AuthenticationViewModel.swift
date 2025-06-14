import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift // Required for setData(from:)

class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var userSession: FirebaseAuth.User? // To hold the user session

    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()

    init() {
        // Listen for Firebase Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.userSession = user
            if user == nil {
                // Potentially clear fields or reset state when user logs out
                // self?.email = ""
                // self?.password = ""
                // self.errorMessage = nil
            }
        }
    }

    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            guard let user = authResult?.user else {
                self.errorMessage = "User creation failed."
                return
            }
            self.createUserProfile(for: user)
            self.errorMessage = nil // Clear error on success
        }
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            // User session is updated by the state listener
            self.errorMessage = nil // Clear error on success
            print("User logged in: \(authResult?.user?.uid ?? "unknown")")
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // User session will be set to nil by the listener
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }

    private func createUserProfile(for user: FirebaseAuth.User) {
        let username = user.email?.split(separator: "@").first.map(String.init) ?? "NewUser"

        // Note: UserProfile's ID is @DocumentID, so Firestore will generate it if nil.
        // However, we want it to be the Firebase Auth UID.
        // So, we explicitly set it. If UserProfile.id was not @DocumentID, this would be fine.
        // If it IS @DocumentID, Firestore Swift SDK expects it to be nil or handles it.
        // For clarity and control, let's assume UserProfile.id is NOT @DocumentID for this write,
        // or that if it is, we are providing it, and it should match the document ID.
        // The provided UserProfile model has `id: String?` with @DocumentID.
        // To set it explicitly to user.uid, we should ensure the UserProfile model's `id` field
        // is either not using @DocumentID OR that we are comfortable with this dual approach.
        // Let's proceed with the assumption that UserProfile's 'id' field will correctly map to user.uid.
        // The UserProfile struct has `id: String?` with `@DocumentID`.
        // If we want to set the document ID to `user.uid`, we should pass `user.uid` to the `document()` call.
        // And UserProfile's `id` field (if it's meant to store the UID) should be distinct from `@DocumentID`
        // or be assigned `user.uid` before encoding if it's not automatically handled by Firestore.
        // The current UserProfile model has `id: String?` marked as @DocumentID.
        // This is fine, as Firestore will populate it when reading. When writing, we can explicitly set the doc ID.

        let newUserProfile = UserProfile(id: user.uid, // Explicitly setting the ID here for clarity in the model
                                         username: username,
                                         bio: nil,
                                         photoURLs: [],
                                         locationSharingEnabled: true,
                                         lastKnownLocation: nil,
                                         isPremiumUser: false,
                                         createdAt: Timestamp(date: Date()), // Client-side timestamp, server will override if @ServerTimestamp works as expected on write
                                         updatedAt: Timestamp(date: Date())) // Client-side, server will override

        do {
            // Set the document ID explicitly to user.uid
            try db.collection("users").document(user.uid).setData(from: newUserProfile) { error in
                if let error = error {
                    // It's good to provide a more user-friendly message or log detailed error
                    self.errorMessage = "Error saving user profile: \(error.localizedDescription)"
                    // Potentially delete the Firebase Auth user if profile creation fails, to allow retry
                    // user.delete { ... }
                } else {
                    print("User profile created for UID: \(user.uid)")
                }
            }
        } catch let error {
            self.errorMessage = "Error encoding user profile: \(error.localizedDescription)"
            // Potentially delete the Firebase Auth user
        }
    }
}
