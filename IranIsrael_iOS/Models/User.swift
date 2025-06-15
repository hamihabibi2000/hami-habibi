import FirebaseFirestoreSwift
import FirebaseFirestore // Required for Timestamp

// Ensure Models directory exists
// mkdir -p IranIsrael_iOS/Models (this will be done by the main command if this subtask is run alone)

struct User: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID will be mapped here
    let username: String
    let email: String
    var profilePhotoUrl: String?
    let createdAt: Timestamp
    var updatedAt: Timestamp

    // If you need to use this User struct with FirebaseAuth.User,
    // you might add an initializer or helper methods.
    // For example, to create a User from a Firebase Auth user and additional details.
}
