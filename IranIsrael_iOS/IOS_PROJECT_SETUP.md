# iOS Project Setup Guide - Iran Israel App

This document outlines the steps to set up the Xcode project for the iOS version of the "Iran Israel" application.

## 1. Create New Xcode Project

1.  Open Xcode.
2.  Select "Create a new Xcode project".
3.  Choose the "App" template under the "iOS" tab.
4.  **Product Name:** `IranIsraelApp` (or similar)
5.  **Team:** Select your development team.
6.  **Organization Identifier:** Your reverse domain name (e.g., `com.yourcompany`)
7.  **Bundle Identifier:** Will be auto-generated (e.g., `com.yourcompany.IranIsraelApp`). **Ensure this matches the bundle ID registered in Firebase.**
8.  **Interface:** `SwiftUI` (Recommended for modern iOS development, but `Storyboard` is also an option if preferred)
9.  **Language:** `Swift`
10. **Storage:** None (Leave unchecked, as we'll use Firebase)
11. **Include Tests:** Check this box to include Unit and UI test targets.
12. Choose a location to save the project.
13. Create the Git repository on your Mac (Xcode usually does this by default).

## 2. Integrate Firebase SDK

It's recommended to use Swift Package Manager (SPM) for Firebase integration.

1.  In Xcode, with your project open, go to **File > Add Packages...**
2.  In the search bar in the top right, paste the Firebase Apple SDK GitHub repository URL:
    `https://github.com/firebase/firebase-ios-sdk.git`
3.  Xcode will fetch the repository. For **Dependency Rule**, choose "Up to Next Major Version".
4.  Click "Add Package".
5.  Select the Firebase products needed for the MVP:
    *   `FirebaseAnalytics` (Recommended, though `FirebaseAnalyticsWithoutAdIdSupport` can be used if IDFA collection is not desired)
    *   `FirebaseAuth` (for user authentication)
    *   `FirebaseFirestore` (for NoSQL database)
    *   `FirebaseFirestoreSwift` (for Codable support with Firestore)
    *   `FirebaseStorage` (for file uploads)
6.  Click "Add Package" again. Xcode will download and integrate the selected libraries.

## 3. Add Firebase Configuration File

1.  **Download `GoogleService-Info.plist`:** If you haven't already, download this file from your Firebase project settings (Project Overview > Project settings > General > Your iOS App > `GoogleService-Info.plist`).
2.  **Add to Project:**
    *   In Xcode, open the Project Navigator (left sidebar).
    *   Drag the downloaded `GoogleService-Info.plist` file into the root of your Xcode project (usually into the main app folder, alongside `AppDelegate.swift` or `YourAppNameApp.swift`).
    *   When prompted, ensure "Copy items if needed" is checked and that the file is added to your main app target.

## 4. Initialize Firebase in App Delegate or App Struct

Depending on whether you're using UIKit App Delegate or SwiftUI App lifecycle:

**For SwiftUI App Lifecycle (e.g., in `YourAppNameApp.swift`):**

```swift
import SwiftUI
import FirebaseCore

// Add this class to handle AppDelegate functionalities if needed with SwiftUI lifecycle
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct IranIsraelApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      ContentView() // Your initial view
    }
  }
}
```

**For UIKit App Delegate (e.g., in `AppDelegate.swift`):**

```swift
import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure() // Initialize Firebase
    return true
  }

  // ... other app delegate methods
}
```

## 5. Next Steps

With the project set up and Firebase integrated, you can proceed to implement:
*   User Authentication UI and Logic
*   Profile Management
*   Content Posting Features
*   Main Feed Display
*   Interactions (Likes, Comments, Follows)

Refer to `FIREBASE_SETUP.md` for the database structure and `DESIGN_GUIDELINES.md` for UI/UX principles.
