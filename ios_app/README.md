# Catch Me Nearby - iOS App

## Setup
This project uses Swift and SwiftUI.

### Firebase Integration
1.  Ensure you have the `GoogleService-Info.plist` file in the `CatchMeNearby/Resources/` directory. This file is obtained from your Firebase project settings.
2.  Firebase SDKs (FirebaseCore, FirebaseAuth, FirebaseFirestore, FirebaseStorage) should be added using Swift Package Manager:
    *   In Xcode: File > Add Packages...
    *   Enter the Firebase GitHub repository URL (e.g., `https://github.com/firebase/firebase-ios-sdk.git`)
    *   Select the required libraries (FirebaseAnalyticsSwift, FirebaseAuth, FirebaseFirestoreSwift, FirebaseStorage). Note: `FirebaseCore` is usually included automatically as a dependency.

### Project Structure

*   **`CatchMeNearby/`**: Main project folder.
    *   **`App/`**: Contains `CatchMeNearbyApp.swift` (main app entry), `AppDelegate.swift`, `SceneDelegate.swift`.
    *   **`Core/`**: For core functionalities.
        *   `Firebase/FirebaseService.swift`: Shared service for Firebase interactions.
        *   `Utils/`: Utility classes and extensions.
    *   **`Features/`**: Modules for different app features.
        *   `Authentication/` (Views, ViewModels for login/signup)
        *   `UserProfile/` (Views, ViewModels, Models for user profiles)
        *   `Discovery/` (Views, ViewModels for user discovery)
        *   `Chat/` (Views, ViewModels for messaging)
        *   `VideoCall/` (Views, ViewModels for video calling)
    *   **`Shared/`**: Reusable components.
        *   `Views/RootView.swift`: Main navigation view.
        *   `Extensions/`: Swift extensions.
        *   `Models/`: Global data models.
    *   **`Resources/`**: Assets and other resources.
        *   `Assets.xcassets/`: Images, colors, etc.
        *   `Fonts/`: Custom fonts.
        *   `GoogleService-Info.plist`: Firebase configuration file.

### Next Steps
1.  Replace the placeholder `GoogleService-Info.plist` with your actual Firebase project's file.
2.  Add Firebase SDKs via Swift Package Manager as described above.
3.  Implement Authentication views and logic.
4.  Develop User Profile features.
5.  Build out Discovery, Chat, and Video Call functionalities.
