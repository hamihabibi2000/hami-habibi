import FirebaseStorage
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var errorMessage: String?
    @Published var currentUser: User? // For storing user profile data

    private var db = Firestore.firestore()

    init() {
        self.userSession = Auth.auth().currentUser
        if let user = userSession {
            fetchUser(uid: user.uid)
        }
    }

    func signUp(email: String, username: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("DEBUG: Failed to create user - \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                self.errorMessage = "Failed to get user from auth result."
                print("DEBUG: Failed to get user from auth result.")
                return
            }
            self.userSession = user
            print("DEBUG: Successfully created user: \(user.uid)")

            // Create user document in Firestore
            let userData: [String: Any] = [
                "username": username,
                "email": email.lowercased(),
                "profilePhotoUrl": "", // Initially empty
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            self.db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                    print("DEBUG: Failed to save user data - \(error.localizedDescription)")
                    // Potentially handle rollback or further error indication
                } else {
                    print("DEBUG: Successfully saved user data for \(user.uid)")
                    self.fetchUser(uid: user.uid) // Fetch the newly created user profile
                }
            }
        }
    }

    func fetchUser(uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch user: \(error.localizedDescription)"
                return
            }
            guard let document = snapshot, document.exists else {
                self.errorMessage = "User document does not exist."
                return
            }
            do {
                self.currentUser = try document.data(as: User.self)
            } catch {
                self.errorMessage = "Failed to decode user: \(error.localizedDescription)"
            }
        }
    }

    // Placeholder for User model (will be in a separate file)
    // For now, AuthViewModel can compile. We'll create User.swift next.

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("DEBUG: Failed to sign in - \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                self.errorMessage = "Failed to get user from auth result on login."
                print("DEBUG: Failed to get user from auth result on login.")
                return
            }
            self.userSession = user
            self.fetchUser(uid: user.uid) // Fetch user profile data
            self.errorMessage = nil // Clear any previous errors
            print("DEBUG: Successfully signed in user: \(user.uid)")
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.errorMessage = nil
            print("DEBUG: User signed out successfully.")
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            print("DEBUG: Error signing out: %@", signOutError)
        }
    }

    func updateProfilePhoto(image: UIImage, completion: @escaping () -> Void) {
        guard let uid = userSession?.uid else {
            self.errorMessage = "No user session found for photo upload."
            DispatchQueue.main.async { completion() }
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            self.errorMessage = "Could not get JPEG data from image."
            DispatchQueue.main.async { completion() }
            return
        }

        let storageRef = Storage.storage().reference()
        let photoRef = storageRef.child("profilePhotos/\(uid)/\(UUID().uuidString).jpg")

        photoRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.errorMessage = "Failed to upload profile photo: \(error.localizedDescription)"
                DispatchQueue.main.async { completion() }
                return
            }
            photoRef.downloadURL { url, error in
                if let error = error {
                    self.errorMessage = "Failed to get download URL: \(error.localizedDescription)"
                    DispatchQueue.main.async { completion() }
                    return
                }
                guard let downloadURL = url else {
                    self.errorMessage = "Download URL was nil."
                    DispatchQueue.main.async { completion() }
                    return
                }
                self.db.collection("users").document(uid).updateData([
                    "profilePhotoUrl": downloadURL.absoluteString,
                    "updatedAt": Timestamp(date: Date())
                ]) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to update profile photo URL: \(error.localizedDescription)"
                        } else {
                            self.currentUser?.profilePhotoUrl = downloadURL.absoluteString
                            self.currentUser?.updatedAt = Timestamp(date:Date()) // Keep local model fresh
                            self.errorMessage = nil
                        }
                        completion()
                    }
                }
            }
        }
    }

    func updateUsername(newUsername: String, completion: @escaping () -> Void) {
        guard let uid = userSession?.uid else {
            self.errorMessage = "No user session found for username update."
            DispatchQueue.main.async { completion() }
            return
        }
        let trimmedUsername = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUsername.isEmpty {
            self.errorMessage = "Username cannot be empty."
            DispatchQueue.main.async { completion() }
            return
        }

        db.collection("users").document(uid).updateData([
            "username": trimmedUsername,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update username: \(error.localizedDescription)"
                } else {
                    self.currentUser?.username = trimmedUsername
                    self.currentUser?.updatedAt = Timestamp(date:Date()) // Keep local model fresh
                    self.errorMessage = nil
                }
                completion()
            }
        }
    }
}
