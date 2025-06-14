import SwiftUI
import FirebaseCore

@main
struct CatchMeNearbyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let locationService = LocationService() // Create the location service instance

    init() {
        FirebaseApp.configure()
        // Additional setup like setting up appearance can go here.
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationService) // Provide LocationService to the environment
                .tint(Color.primaryAccentPurple) // Sets global tint for controls like Button, Picker, etc.
        }
    }
}

// Minimal AppDelegate to handle app lifecycle for location service
class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Access LocationService instance if needed, e.g., if it's a singleton:
        // LocationService.shared.appDidEnterForeground()
        // Or, if passed around, the main view/controller should handle this.
        // For this example, assuming the view model that uses LocationService will handle foreground.
        // The current LocationService has an appDidEnterForeground method.
        // This could be called via a NotificationCenter post from here, or directly if accessible.
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Similar to above, notify LocationService if needed.
        // LocationService.shared.appDidEnterBackground()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}
