import Foundation
import FirebaseFirestore // For GeoPoint and Timestamp
import FirebaseFirestoreSwift // For @DocumentID

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String? // If using Firestore's automatic ID mapping. Often, you manage this as Auth UID.
    // var id: String // Alternatively, if you set it manually from Auth UID.

    var username: String
    var bio: String?
    var photoURLs: [String]? // Array of URLs, max 7
    var locationSharingEnabled: Bool
    var lastKnownLocation: GeoPoint? // Firestore GeoPoint
    var isPremiumUser: Bool

    @ServerTimestamp var createdAt: Timestamp? // Firestore server timestamp
    @ServerTimestamp var updatedAt: Timestamp? // Firestore server timestamp

    // CodingKeys for mapping Firestore field names if they differ or for custom handling
    // If your Swift property names match Firestore field names, this is often not strictly necessary
    // unless you have optionality differences or specific naming conventions.
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case bio
        case photoURLs
        case locationSharingEnabled
        case lastKnownLocation
        case isPremiumUser
        case createdAt
        case updatedAt
    }

    // Initializer with default values
    // The @DocumentID 'id' will be populated by Firestore if it's not set before encoding.
    // If you are setting 'id' manually (e.g. to Firebase Auth UID), ensure it's done before saving.
    init(id: String? = nil, // Allow nil for @DocumentID to be auto-populated by Firestore
         username: String,
         bio: String? = nil,
         photoURLs: [String]? = [],
         locationSharingEnabled: Bool = true,
         lastKnownLocation: GeoPoint? = nil,
         isPremiumUser: Bool = false,
         createdAt: Timestamp? = nil, // These will be set by server
         updatedAt: Timestamp? = nil) { // These will be set by server
        self.id = id
        self.username = username
        self.bio = bio
        // Ensure photoURLs does not exceed 7 items if that's a hard rule.
        // This basic model doesn't enforce it; that would be business logic.
        self.photoURLs = photoURLs
        self.locationSharingEnabled = locationSharingEnabled
        self.lastKnownLocation = lastKnownLocation
        self.isPremiumUser = isPremiumUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Example of how you might enforce the 7 photo URL limit if needed:
extension UserProfile {
    mutating func setPhotoURLs(_ urls: [String]) {
        self.photoURLs = Array(urls.prefix(7))
    }
}
