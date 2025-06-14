package com.catchmenearby.features.auth.viewmodel;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.catchmenearby.features.profile.model.UserProfile;
import java.util.ArrayList;
// No need to import java.util.Date explicitly if not using it directly here

public class AuthViewModel extends ViewModel {
    private FirebaseAuth mAuth;
    private FirebaseFirestore db;

    private MutableLiveData<FirebaseUser> userLiveData;
    private MutableLiveData<String> errorMessageLiveData;
    private MutableLiveData<Boolean> isLoadingLiveData;


    public AuthViewModel() {
        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();
        userLiveData = new MutableLiveData<>();
        errorMessageLiveData = new MutableLiveData<>();
        isLoadingLiveData = new MutableLiveData<>();

        // Set initial user state
        userLiveData.setValue(mAuth.getCurrentUser());

        // Listen for auth state changes
        mAuth.addAuthStateListener(firebaseAuth -> {
            userLiveData.setValue(firebaseAuth.getCurrentUser());
            if (firebaseAuth.getCurrentUser() == null) {
                // Clear errors or perform other cleanup when user logs out
                errorMessageLiveData.postValue(null);
                isLoadingLiveData.postValue(false);
            }
        });
    }

    public LiveData<FirebaseUser> getUserLiveData() { return userLiveData; }
    public LiveData<String> getErrorMessageLiveData() { return errorMessageLiveData; }
    public LiveData<Boolean> getIsLoadingLiveData() { return isLoadingLiveData; }


    public void signUp(String email, String password) {
        isLoadingLiveData.setValue(true);
        errorMessageLiveData.setValue(null);
        mAuth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(task -> {
                isLoadingLiveData.setValue(false);
                if (task.isSuccessful() && task.getResult() != null && task.getResult().getUser() != null) {
                    FirebaseUser user = task.getResult().getUser();
                    createUserProfile(user, email);
                    // UserLiveData will be updated by AuthStateListener
                } else {
                    errorMessageLiveData.setValue(task.getException() != null ? task.getException().getMessage() : "Signup failed. Please try again.");
                }
            });
    }

    public void login(String email, String password) {
        isLoadingLiveData.setValue(true);
        errorMessageLiveData.setValue(null);
        mAuth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener(task -> {
                isLoadingLiveData.setValue(false);
                if (task.isSuccessful()) {
                    // UserLiveData will be updated by AuthStateListener
                } else {
                    errorMessageLiveData.setValue(task.getException() != null ? task.getException().getMessage() : "Login failed. Please check credentials.");
                }
            });
    }

    public void signOut() {
        mAuth.signOut();
        // UserLiveData will be updated by AuthStateListener
    }

    private void createUserProfile(FirebaseUser firebaseUser, String email) {
        String username = email.contains("@") ? email.substring(0, email.indexOf('@')) : firebaseUser.getUid().substring(0, Math.min(firebaseUser.getUid().length(), 10)); // Default username
        UserProfile profile = new UserProfile(
            firebaseUser.getUid(),
            username,
            null, // bio
            new ArrayList<>(), // photoURLs
            true, // locationSharingEnabled
            null, // lastKnownLocation
            false // isPremiumUser
        );
        // Note: createdAt and updatedAt fields in UserProfile.java are annotated with @ServerTimestamp.
        // Firestore will automatically populate these fields on the server.
        // So, no need to set them manually here (e.g., profile.setCreatedAt(new Date());)

        db.collection("users").document(firebaseUser.getUid()).set(profile)
            .addOnSuccessListener(aVoid -> System.out.println("User profile created for UID: " + firebaseUser.getUid()))
            .addOnFailureListener(e -> {
                System.err.println("Error saving user profile: " + e.getMessage());
                errorMessageLiveData.postValue("Error creating profile: " + e.getMessage() + ". Please try logging in.");
                // Optional: Delete the Firebase Auth user if profile creation fails critically
                // firebaseUser.delete().addOnCompleteListener(deleteTask -> {
                //     if (deleteTask.isSuccessful()) {
                //         errorMessageLiveData.postValue("Signup failed: Could not create profile. Please try again.");
                //     }
                // });
            });
    }
}
