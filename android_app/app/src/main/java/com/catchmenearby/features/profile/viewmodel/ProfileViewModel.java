package com.catchmenearby.features.profile.viewmodel;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FirebaseFirestore;
// import com.google.firebase.storage.FirebaseStorage; // For photo uploads later
// import com.google.firebase.storage.StorageReference; // For photo uploads later
import com.catchmenearby.features.profile.model.UserProfile;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class ProfileViewModel extends ViewModel {
    private FirebaseFirestore db = FirebaseFirestore.getInstance();
    // private FirebaseStorage storage = FirebaseStorage.getInstance(); // For photo uploads
    private FirebaseAuth auth = FirebaseAuth.getInstance();

    private MutableLiveData<UserProfile> userProfileLiveData = new MutableLiveData<>();
    // MutableLiveData for individual editable fields, two-way bound or updated from UI
    private MutableLiveData<String> username = new MutableLiveData<>();
    private MutableLiveData<String> bio = new MutableLiveData<>();
    private MutableLiveData<Boolean> locationSharingEnabled = new MutableLiveData<>(true); // Default
    private MutableLiveData<List<String>> photoItems = new MutableLiveData<>(new ArrayList<>());

    private MutableLiveData<Boolean> isLoading = new MutableLiveData<>(false);
    private MutableLiveData<String> errorMessage = new MutableLiveData<>();
    private MutableLiveData<Boolean> saveSuccess = new MutableLiveData<>(false);

    public ProfileViewModel() {
        fetchUserProfile();
    }

    // LiveData getters for observing in Activity/Fragment
    public LiveData<UserProfile> getUserProfileLiveData() { return userProfileLiveData; }
    public LiveData<String> getUsernameState() { return username; } // Changed name to avoid conflict
    public LiveData<String> getBioState() { return bio; } // Changed name to avoid conflict
    public LiveData<Boolean> getLocationSharingEnabledState() { return locationSharingEnabled; } // Changed name
    public LiveData<List<String>> getPhotoItemsState() { return photoItems; } // Changed name
    public LiveData<Boolean> getIsLoading() { return isLoading; }
    public LiveData<String> getErrorMessage() { return errorMessage; }
    public LiveData<Boolean> getSaveSuccess() { return saveSuccess; }

    // Methods to update individual fields from UI (e.g., after EditText changes)
    public void updateUsername(String uname) { username.setValue(uname); }
    public void updateBio(String userBio) { bio.setValue(userBio); }
    public void updateLocationSharingEnabled(boolean enabled) { locationSharingEnabled.setValue(enabled); }


    public void fetchUserProfile() {
        FirebaseUser currentUser = auth.getCurrentUser();
        if (currentUser == null) {
            errorMessage.setValue("User not logged in.");
            return;
        }
        isLoading.setValue(true);
        db.collection("users").document(currentUser.getUid()).get()
            .addOnSuccessListener(documentSnapshot -> {
                isLoading.setValue(false);
                if (documentSnapshot.exists()) {
                    UserProfile profile = documentSnapshot.toObject(UserProfile.class);
                    userProfileLiveData.setValue(profile); // This is the "master" copy
                    if (profile != null) {
                        // Initialize editable LiveData from the fetched profile
                        username.setValue(profile.getUsername());
                        bio.setValue(profile.getBio() == null ? "" : profile.getBio());
                        locationSharingEnabled.setValue(profile.isLocationSharingEnabled());
                        photoItems.setValue(profile.getPhotoURLs() != null ? new ArrayList<>(profile.getPhotoURLs()) : new ArrayList<>());
                        errorMessage.setValue(null);
                    } else {
                         errorMessage.setValue("Failed to parse profile data.");
                    }
                } else {
                    errorMessage.setValue("Profile document does not exist. Please complete signup or contact support.");
                }
            })
            .addOnFailureListener(e -> {
                isLoading.setValue(false);
                errorMessage.setValue("Error fetching profile: " + e.getMessage());
            });
    }

    public void saveProfile() {
        FirebaseUser currentUser = auth.getCurrentUser();
        // Use a local copy of userProfile or construct a new one for saving
        // This helps if userProfileLiveData.getValue() is null for some reason
        UserProfile profileToSave;
        if (userProfileLiveData.getValue() != null) {
            profileToSave = userProfileLiveData.getValue();
        } else {
            // Fallback or error, ideally profile should be loaded
            profileToSave = new UserProfile();
            profileToSave.setId(currentUser != null ? currentUser.getUid() : "error_no_uid");
        }


        if (currentUser == null) {
            errorMessage.setValue("User not logged in. Cannot save profile.");
            return;
        }
        isLoading.setValue(true);
        saveSuccess.setValue(false); // Reset save success status

        DocumentReference profileRef = db.collection("users").document(currentUser.getUid());

        // Update the profile object with values from the UI-bound LiveData
        profileToSave.setUsername(username.getValue());
        String bioValue = bio.getValue();
        profileToSave.setBio(bioValue != null && bioValue.trim().isEmpty() ? null : bioValue);
        profileToSave.setLocationSharingEnabled(locationSharingEnabled.getValue() != null ? locationSharingEnabled.getValue() : true);
        profileToSave.setPhotoURLs(photoItems.getValue()); // Assumes photoItems LiveData holds the current list of URLs
        // profileToSave.setUpdatedAt(new Date()); // Let @ServerTimestamp handle this

        profileRef.set(profileToSave) // Overwrites the document with the content of profileToSave
                                      // Use .update() for specific fields if that's preferred.
                                      // If UserProfile.java has @ServerTimestamp on updatedAt, it will be handled by server.
            .addOnSuccessListener(aVoid -> {
                isLoading.setValue(false);
                errorMessage.setValue(null); // Clear any previous error
                saveSuccess.setValue(true); // Signal success
                userProfileLiveData.setValue(profileToSave); // Update the "master" LiveData
                System.out.println("Profile saved successfully for UID: " + currentUser.getUid());
            })
            .addOnFailureListener(e -> {
                isLoading.setValue(false);
                errorMessage.setValue("Error saving profile: " + e.getMessage());
                saveSuccess.setValue(false);
            });
    }

    public void addPhotoPlaceholder(String placeholderURL) {
        List<String> currentPhotos = photoItems.getValue();
        if (currentPhotos == null) {
            currentPhotos = new ArrayList<>();
        }
        if (currentPhotos.size() < 7) {
            ArrayList<String> updatedPhotos = new ArrayList<>(currentPhotos);
            updatedPhotos.add(placeholderURL);
            photoItems.setValue(updatedPhotos);
        } else {
            errorMessage.setValue("Maximum of 7 photos allowed.");
        }
    }

    public void removePhotoAtIndex(int index) {
         List<String> currentPhotos = photoItems.getValue();
         if (currentPhotos != null && index >= 0 && index < currentPhotos.size()) {
             ArrayList<String> updatedPhotos = new ArrayList<>(currentPhotos);
             updatedPhotos.remove(index);
             photoItems.setValue(updatedPhotos);
         }
    }

    // Method to get current user ID, useful for ViewProfileActivity logic
    public String getCurrentUserId() {
        FirebaseUser currentUser = auth.getCurrentUser();
        return (currentUser != null) ? currentUser.getUid() : null;
    }

    // Method to fetch a specific user's profile by their ID
    public void fetchSpecificUserProfile(String userId) {
        if (userId == null || userId.isEmpty()) {
            errorMessage.setValue("User ID is invalid.");
            return;
        }
        isLoading.setValue(true);
        // Clear existing profile data before fetching new one, or indicate it's for a different user
        // userProfileLiveData.setValue(null); // Optional: clear previous profile

        db.collection("users").document(userId).get()
            .addOnSuccessListener(documentSnapshot -> {
                isLoading.setValue(false);
                if (documentSnapshot.exists()) {
                    UserProfile profile = documentSnapshot.toObject(UserProfile.class);
                    userProfileLiveData.setValue(profile); // This will be observed by ViewProfileActivity
                    if (profile != null) {
                        // These are for editing, ViewProfileActivity will use userProfileLiveData directly
                        // username.setValue(profile.getUsername());
                        // bio.setValue(profile.getBio() == null ? "" : profile.getBio());
                        // locationSharingEnabled.setValue(profile.isLocationSharingEnabled());
                        // photoItems.setValue(profile.getPhotoURLs() != null ? new ArrayList<>(profile.getPhotoURLs()) : new ArrayList<>());
                        errorMessage.setValue(null);
                    } else {
                        errorMessage.setValue("Failed to parse profile data for user: " + userId);
                    }
                } else {
                    errorMessage.setValue("Profile document does not exist for user: " + userId);
                }
            })
            .addOnFailureListener(e -> {
                isLoading.setValue(false);
                errorMessage.setValue("Error fetching profile for user " + userId + ": " + e.getMessage());
            });
    }
}
