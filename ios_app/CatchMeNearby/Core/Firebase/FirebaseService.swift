import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService {
    static let shared = FirebaseService()

    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    let storage = Storage.storage()

    private init() {}

    // Placeholder for common Firebase operations
}
