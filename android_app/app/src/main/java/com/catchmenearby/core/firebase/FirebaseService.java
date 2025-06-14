package com.catchmenearby.core.firebase;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;

public class FirebaseService {
    private static FirebaseService instance;

    public final FirebaseAuth auth;
    public final FirebaseFirestore firestore;
    public final FirebaseStorage storage;

    private FirebaseService() {
        auth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();
        storage = FirebaseStorage.getInstance();
    }

    public static synchronized FirebaseService getInstance() {
        if (instance == null) {
            instance = new FirebaseService();
        }
        return instance;
    }
    // Placeholder for common Firebase operations
}
