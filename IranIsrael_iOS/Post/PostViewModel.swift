import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestoreSwift // For Codable support

class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    // Upload Post
    // For MVP, we'll handle a single image or video first. Multi-image later.
    // MediaItems will be a struct/class to hold the data and type (image/video)

    struct MediaItem {
        let type: MediaType // "photo" or "video"
        let data: Data
        let fileExtension: String // e.g., "jpg", "mp4"
    }

    enum MediaType: String {
        case photo = "photo"
        case video = "video"
    }

    func uploadPost(caption: String?, mediaItems: [MediaItem], user: User, completion: @escaping (Bool) -> Void) {
        guard !mediaItems.isEmpty else {
            self.errorMessage = "No media selected for the post."
            completion(false)
            return
        }

        guard let userID = user.id else {
            self.errorMessage = "User ID not found."
            completion(false)
            return
        }

        self.isLoading = true
        self.errorMessage = nil

        var uploadedMediaUrls: [String] = []
        let dispatchGroup = DispatchGroup()

        for item in mediaItems {
            dispatchGroup.enter()
            let uniqueID = UUID().uuidString
            let storageRef = storage.reference().child("postMedia/\(userID)/\(uniqueID).\(item.fileExtension)")

            storageRef.putData(item.data, metadata: nil) { metadata, error in
                if let error = error {
                    self.errorMessage = "Failed to upload \(item.type.rawValue): \(error.localizedDescription)"
                    print("DEBUG: Upload error - \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        self.errorMessage = "Failed to get download URL for \(item.type.rawValue): \(error.localizedDescription)"
                        print("DEBUG: Download URL error - \(error.localizedDescription)")
                    } else if let url = url {
                        uploadedMediaUrls.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if uploadedMediaUrls.count != mediaItems.count {
                // Not all media uploaded successfully
                self.isLoading = false
                // Error message should already be set by one of the failing uploads
                if self.errorMessage == nil { // Generic error if none specific
                     self.errorMessage = "Failed to upload some media items."
                }
                completion(false)
                return
            }

            // All media uploaded, now create Firestore document
            let post = Post(
                userID: userID,
                username: user.username,
                userProfilePhotoUrl: user.profilePhotoUrl,
                mediaUrls: uploadedMediaUrls,
                mediaType: mediaItems.first?.type.rawValue ?? "photo", // Assuming all items are of the same type for MVP
                caption: caption,
                createdAt: Timestamp(date: Date())
            )

            do {
                try self.db.collection("posts").addDocument(from: post) { error in
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = "Failed to save post to Firestore: \(error.localizedDescription)"
                        print("DEBUG: Firestore save error - \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("DEBUG: Post successfully uploaded and saved!")
                        completion(true)
                    }
                }
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to encode post: \(error.localizedDescription)"
                print("DEBUG: Post encoding error - \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // We will add fetchPosts methods later
}
