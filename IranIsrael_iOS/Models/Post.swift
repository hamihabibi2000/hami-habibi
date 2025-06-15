import FirebaseFirestoreSwift
import FirebaseFirestore // For Timestamp

struct Post: Identifiable, Codable, Hashable { // Added Hashable
    @DocumentID var id: String?
    let userID: String // UID of the user who created the post
    var username: String // Username of the post creator (for easy display)
    var userProfilePhotoUrl: String? // Profile photo URL of post creator

    var mediaUrls: [String] // URLs to photos/videos in Firebase Storage
    var mediaType: String // "photo" or "video" (MVP: one type per post)
    var caption: String? // Optional caption

    var likeCount: Int = 0
    var commentCount: Int = 0

    let createdAt: Timestamp
    var updatedAt: Timestamp? // Optional, if posts can be edited

    // For identifiable in loops and potentially for diffing if needed
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    // Example of a computed property if needed, e.g., for display
    var creationDate: Date {
        createdAt.dateValue()
    }
}
