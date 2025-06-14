package com.catchmenearby.features.profile.model;

import com.google.firebase.firestore.Exclude;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.ServerTimestamp;
import java.util.Date;
import java.util.List;
import java.util.ArrayList;

public class UserProfile {
    private String id; // Document ID, typically Firebase Auth UID
    private String username;
    private String bio;
    private List<String> photoURLs; // Max 7
    private boolean locationSharingEnabled;
    private GeoPoint lastKnownLocation; // Firestore GeoPoint
    private boolean isPremiumUser; // Default false
    private Date createdAt;
    private Date updatedAt;

    // Important: Default constructor required for Firestore deserialization
    public UserProfile() {
        // Initialize lists to avoid null pointer exceptions if not set by Firestore
        this.photoURLs = new ArrayList<>();
        // Default values for primitives are fine (false for boolean, null for objects)
    }

    public UserProfile(String id, String username, String bio, List<String> photoURLs,
                       boolean locationSharingEnabled, GeoPoint lastKnownLocation, boolean isPremiumUser) {
        this.id = id;
        this.username = username;
        this.bio = bio;
        setPhotoURLs(photoURLs); // Use setter to enforce limit
        this.locationSharingEnabled = locationSharingEnabled;
        this.lastKnownLocation = lastKnownLocation;
        this.isPremiumUser = isPremiumUser;
        // createdAt and updatedAt are typically set by the server or on creation using @ServerTimestamp
    }

    // Use @Exclude for the ID if you are letting Firestore manage the document ID
    // and you don't want to write it back into the document data itself.
    // However, it's common to store the UID as the document ID AND in the document for querying.
    // For this model, we assume 'id' is the UID and is also the document's ID.
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public List<String> getPhotoURLs() { return photoURLs; }
    public void setPhotoURLs(List<String> photoURLs) {
        if (photoURLs != null) {
            if (photoURLs.size() > 7) {
                this.photoURLs = new ArrayList<>(photoURLs.subList(0, 7));
            } else {
                this.photoURLs = new ArrayList<>(photoURLs);
            }
        } else {
            this.photoURLs = new ArrayList<>();
        }
    }

    public boolean isLocationSharingEnabled() { return locationSharingEnabled; }
    public void setLocationSharingEnabled(boolean locationSharingEnabled) { this.locationSharingEnabled = locationSharingEnabled; }

    public GeoPoint getLastKnownLocation() { return lastKnownLocation; }
    public void setLastKnownLocation(GeoPoint lastKnownLocation) { this.lastKnownLocation = lastKnownLocation; }

    public boolean isPremiumUser() { return isPremiumUser; }
    public void setPremiumUser(boolean premiumUser) { isPremiumUser = premiumUser; }

    @ServerTimestamp // Annotation for Firestore to populate server timestamp on creation
    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    @ServerTimestamp // Annotation for Firestore to populate server timestamp on creation/update
    public Date getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Date updatedAt) { this.updatedAt = updatedAt; }
}
