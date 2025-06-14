# Catch Me Nearby - Android App

## Setup
This project uses Java, XML for layouts, and Material Components.

### Firebase Integration
1.  Ensure you have the `google-services.json` file in the `android_app/app/` directory. This file is obtained from your Firebase project settings.
2.  Firebase SDKs (e.g., `firebase-bom`, `firebase-auth`, `firebase-firestore`, `firebase-storage`) are included as dependencies in `app/build.gradle`.
3.  The Google Services plugin (`com.google.gms.google-services`) is applied in the project-level `build.gradle` and app-level `app/build.gradle`.

### Project Structure
The project follows a standard Android Gradle structure:
*   `app/src/main/java/com/catchmenearby/`: Root package for Java code.
    *   `MainApplication.java`: Custom Application class for Firebase initialization.
    *   `MainActivity.java`: Main activity of the app.
    *   `core/`: Core components like Firebase services, utilities.
        *   `firebase/FirebaseService.java`: Singleton for Firebase operations.
        *   `utils/`: Utility classes.
    *   `features/`: Feature-specific modules (Authentication, Profile, Discovery, Chat, VideoCall).
        *   Each feature has `ui` (Activities/Fragments), `viewmodel`, and sometimes `model` sub-packages.
    *   `shared/`: Shared UI components, global models.
*   `app/src/main/res/`: Resource files.
    *   `layout/`: XML layout files (e.g., `activity_main.xml`).
    *   `navigation/`: Jetpack Navigation graphs (e.g., `app_nav_graph.xml`).
    *   `menu/`: Menu XML files (e.g., `bottom_nav_menu.xml`).
    *   `values/`: Value resources like `colors.xml`, `strings.xml`, `themes.xml`.
    *   `drawable/`: Placeholder for image assets.
*   `build.gradle`: Project-level Gradle build script.
*   `app/build.gradle`: App-module-level Gradle build script.

### Conceptual AndroidManifest.xml Entries
The `app/src/main/AndroidManifest.xml` (which would be created in a full Android Studio project, but is not managed by this toolset unless explicitly created as a file) is crucial and would need:

*   **Application Theme and Name:**
    The `<application>` tag should reference the custom `MainApplication` and the defined theme.
    ```xml
    <application
        android:name=".MainApplication"
        android:label="@string/app_name"
        android:theme="@style/Theme.CatchMeNearby"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:allowBackup="true">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Other activities, services, etc. would also be declared here -->
        <!-- Ensure other activities also use Theme.CatchMeNearby or a derivative if they don't need NoActionBar -->

    </application>
    ```

*   **Internet Permission:**
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    ```

*   **Future Permissions (Placeholders):**
    ```xml
    <!-- <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" /> -->
    <!-- <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" /> -->
    ```

### Next Steps
1.  Create an `AndroidManifest.xml` file at `android_app/app/src/main/AndroidManifest.xml` with the content described above (or ensure your IDE generates it with these settings).
2.  Replace the placeholder `google-services.json` with your actual Firebase project's file.
2.  Sync the Gradle project to download dependencies.
3.  Implement a placeholder `AndroidManifest.xml` or ensure it's correctly configured if using a full IDE setup.
4.  Develop the Authentication flow (UI, ViewModels, logic).
5.  Build out User Profile, Discovery, Chat, and Video Call features.
6.  Refine layouts, navigation, and add actual drawables.
