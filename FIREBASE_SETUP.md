# Firebase Setup Guide - Iran Israel App

This document outlines the steps for setting up the Firebase project and the data structures for the "Iran Israel" application.

## 1. Firebase Project Creation & Configuration (Manual Steps)

These steps are performed in the [Firebase Console](https://console.firebase.google.com/):

*   **Create a New Project:**
    *   Click on "Add project".
    *   Enter a project name (e.g., "IranIsraelNewsFeed").
    *   Accept terms and create the project.
    *   It's recommended to enable Google Analytics for this project for future insights, though not strictly required for MVP functionality.
*   **Add iOS App:**
    *   Go to Project Settings -> General.
    *   Click on the iOS icon to "Add app".
    *   Enter iOS bundle ID (e.g., `com.iranisrael.newsapp`).
    *   Download `GoogleService-Info.plist` and add it to the Xcode project.
    *   Follow SDK integration instructions.
*   **Add Android App:**
    *   Go to Project Settings -> General.
    *   Click on the Android icon to "Add app".
    *   Enter Android package name (e.g., `com.iranisrael.newsapp`).
    *   Enter SHA-1 signing certificate fingerprint (for Google Sign-In if used later, and for Firebase Dynamic Links, etc. Can be added later but good to be aware of).
    *   Download `google-services.json` and add it to the Android project's `app` module.
    *   Follow SDK integration instructions.
*   **Enable Authentication:**
    *   Go to Authentication -> Sign-in method.
    *   Enable "Email/Password" provider.
*   **Set up Cloud Firestore:**
    *   Go to Firestore Database -> Create database.
    *   Start in **production mode** (this ensures security rules are enforced from the start).
    *   Choose a Cloud Firestore location (e.g., a region geographically relevant to your target audience, if possible, or a default one).
*   **Set up Firebase Storage:**
    *   Go to Storage -> Get started.
    *   Follow the prompts to set up storage.
    *   Note the default bucket URL.

## 2. Cloud Firestore Data Structure

### Users Collection (`users`)

*   **Document ID:** `userID` (Firebase Auth UID)
*   **Fields:**
    *   `username`: String (e.g., "user123")
    *   `email`: String (e.g., "user@example.com")
    *   `profilePhotoUrl`: String (URL to image in Firebase Storage, optional)
    *   `createdAt`: Timestamp
    *   `updatedAt`: Timestamp

### Posts Collection (`posts`)

*   **Document ID:** Auto-generated
*   **Fields:**
    *   `userID`: String (UID of the user who created the post)
    *   `mediaUrls`: Array of Strings (URLs to photos/videos in Firebase Storage)
        *   Example: `["url_to_image1.jpg", "url_to_video.mp4"]`
    *   `mediaType`: String ("photo" or "video") - *Note: Could also be inferred or stored per media item if mixing in one post was allowed later.* For MVP, assume one type per post.
    *   `caption`: String (max 280 characters)
    *   `likeCount`: Number (integer, defaults to 0)
    *   `commentCount`: Number (integer, defaults to 0)
    *   `createdAt`: Timestamp (used for reverse chronological order)
    *   `updatedAt`: Timestamp
    *   `regionTag`: String (e.g., "Iran", "Israel", "Regional" - for potential future filtering, though MVP shows all) - *Consider if this is needed for MVP or future.* For now, assume all posts are relevant.

### Likes Subcollection (within each `posts` document)

*   To check if a user has liked a post and to store like information efficiently.
*   **Collection Path:** `posts/{postID}/likes`
*   **Document ID:** `userID` (UID of the user who liked the post)
*   **Fields:**
    *   `likedAt`: Timestamp

### Comments Subcollection (within each `posts` document)

*   **Collection Path:** `posts/{postID}/comments`
*   **Document ID:** Auto-generated
*   **Fields:**
    *   `userID`: String (UID of the user who commented)
    *   `username`: String (username of the commenter, for easy display)
    *   `profilePhotoUrl`: String (optional, for easy display)
    *   `commentText`: String
    *   `createdAt`: Timestamp

### Follows Collection (`follows`)

*   Used to manage user follow relationships. This allows for building personalized feeds.
*   This collection stores who is following whom.
*   **Document ID:** `followerUserID_followingUserID` (e.g., `uid1_uid2` means uid1 follows uid2)
    *   Alternatively, use subcollections: `users/{userID}/following/{followingUserID}` and `users/{userID}/followers/{followerUserID}`. For MVP, a single collection with combined IDs can be simpler for querying "who a user is following". For "who follows a user", subcollections might be more direct. Let's propose subcollections for better scalability.

#### Revised Follows Structure (Using Subcollections):

*   **Path for users someone is following:** `users/{currentUserID}/following/{targetUserID}`
    *   **Document ID:** `targetUserID`
    *   **Fields:** `followedAt`: Timestamp
*   **Path for a user's followers:** `users/{targetUserID}/followers/{currentUserID}`
    *   **Document ID:** `currentUserID`
    *   **Fields:** `followedAt`: Timestamp

    *This dual write/maintenance approach is common for social apps. For MVP, if personalized feed is just "show posts from users I follow", the first path (`users/{currentUserID}/following`) is the primary one needed for reads.*

### Reports Collection (`reports`)

*   **Document ID:** Auto-generated
*   **Fields:**
    *   `reportedPostID`: String (ID of the post being reported)
    *   `reportingUserID`: String (UID of the user who made the report)
    *   `reason`: String (optional, could be a predefined list or free text in later versions)
    *   `reportedAt`: Timestamp
    *   `status`: String (e.g., "pending_review", "resolved", "dismissed" - for manual tracking)

## 3. Firebase Storage Security Rules (Basic)

Location: Firebase Console -> Storage -> Rules

```rules
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Profile Photos: Allow read by anyone, write by authenticated user matching userID
    match /profilePhotos/{userID}/{fileName} {
      allow read;
      allow write: if request.auth != null && request.auth.uid == userID;
    }

    // Post Media (Photos/Videos): Allow read by anyone, write by authenticated users
    match /postMedia/{userID}/{postID}/{fileName} {
      allow read;
      // Ensure user is authenticated to upload. {userID} in path should match their UID.
      // {postID} can be generated client-side before upload or a placeholder.
      allow write: if request.auth != null && request.auth.uid == userID;
      // Add size validation, e.g., request.resource.size < 5 * 1024 * 1024 for photos
      // request.resource.size < 50 * 1024 * 1024 for videos (adjust as needed)
      // Add content type validation if possible, e.g. request.resource.contentType.matches('image/.*')
    }
  }
}
```

*Note: These are basic rules. More granular control (e.g., file types, sizes) should be added.*

## 4. Cloud Firestore Security Rules (Basic)

Location: Firebase Console -> Firestore Database -> Rules

```rules
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Users: Allow read by anyone, create by anyone (for sign-up), update only by the user themselves.
    match /users/{userID} {
      allow read: if true;
      allow create: if request.auth != null; // User is creating their own profile doc after sign-up
      allow update: if request.auth != null && request.auth.uid == userID;
      // No delete for now, or restrict to admin role in future.
    }

    // Posts: Allow read by anyone. Allow create, update, delete only by the authenticated user who owns the post.
    match /posts/{postID} {
      allow read: if true;
      allow create: if request.auth != null && request.resource.data.userID == request.auth.uid;
      allow update: if request.auth != null && resource.data.userID == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userID == request.auth.uid;

      // Likes subcollection
      match /likes/{userID} {
        allow read: if true;
        // Allow create/delete if user is authenticated and userID in path is their own UID
        allow write: if request.auth != null && request.auth.uid == userID;
      }

      // Comments subcollection
      match /comments/{commentID} {
        allow read: if true;
        allow create: if request.auth != null && request.resource.data.userID == request.auth.uid;
        // Update/Delete rules for comments can be added if needed (e.g., user can edit/delete their own comment)
        allow update: if request.auth != null && resource.data.userID == request.auth.uid;
        allow delete: if request.auth != null && resource.data.userID == request.auth.uid;
      }
    }

    // Follows: User can manage their own "following" list.
    // User can read their own followers and who they are following.
    // Structure: /users/{currentUserID}/following/{targetUserID}
    // Structure: /users/{targetUserID}/followers/{currentUserID}
    match /users/{userID}/following/{targetUserID} {
      allow read: if request.auth != null && request.auth.uid == userID;
      allow write: if request.auth != null && request.auth.uid == userID; // User manages their own following list
    }
    match /users/{userID}/followers/{followerUserID} {
      allow read: if request.auth != null && request.auth.uid == userID;
      // Generally, followers list is written to by the other user's action of following.
      // Direct write might be disallowed or restricted.
      // For MVP, the `following` collection is primary for reads.
      allow write: if request.auth != null && request.auth.uid == followerUserID; // The follower is creating the entry
    }

    // Reports: Allow authenticated users to create reports. Read/Update/Delete typically restricted to admin/moderator roles (not defined in MVP).
    match /reports/{reportID} {
      allow create: if request.auth != null;
      // For MVP, no read/update/delete rules for users. Admins would access via Firebase console or a separate admin app.
      allow read, update, delete: if false; // Or implement admin role check
    }
  }
}
```
*Note: These are foundational rules. They should be tested thoroughly and refined, especially around writes and data validation (e.g., ensuring `userID` fields match `request.auth.uid` on creation).*
