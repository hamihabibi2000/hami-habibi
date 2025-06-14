import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()

    var body: some View {
        // Content based on authentication state
        // Group is used here to allow conditional content without a container view
        // that might interfere with background or other modifiers.
        Group {
            if authViewModel.userSession != nil {
                MainAppTabView()
                    .environmentObject(authViewModel) // Pass it down if any child views need to call signOut, etc.
            } else {
                LoginView() // This view now handles its own navigation to SignUpView
            }
        }
        .onAppear {
            // Configure UITabBar appearance (this is a global setting)
            // These settings might be better placed in AppDelegate or App struct's init
            // if they need to be configured once at app launch.
            // However, onAppear in RootView is also a common place.
            let tabBarAppearance = UITabBarAppearance()

            // Configure the background color of the tab bar
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(Color.secondaryBackgroundDarkGray)

            // Configure the color of selected tab item
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryAccentPurple)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.primaryAccentPurple)]

            // Configure the color of unselected tab items
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.secondaryTextCyan)
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.secondaryTextCyan)]

            // Apply the appearance to standard and scroll edge (if applicable)
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}

struct MainAppTabView: View {
    // Access the authViewModel from the environment
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var locationService: LocationService // Get LocationService from environment
    // ViewModel for the current user's profile data for viewing and editing
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingEditProfile = false

    var body: some View {
        TabView {
            Text("Discovery Tab") // Replace with actual DiscoveryView
                .foregroundColor(Color.primaryTextWhite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackgroundBlack.ignoresSafeArea())
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            Text("Matches Tab") // Replace with actual MatchesView
                .foregroundColor(Color.primaryTextWhite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackgroundBlack.ignoresSafeArea())
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }

            // Profile Tab - displays the logged-in user's profile
            NavigationView { // Added NavigationView for a title bar on ViewUserProfileView
                VStack(spacing: 0) { // Use spacing 0 if ViewUserProfileView handles its own padding
                    if profileViewModel.isLoading && profileViewModel.userProfile == nil {
                        ProgressView().padding()
                        Text("Loading Your Profile...")
                            .foregroundColor(Color.primaryTextWhite)
                    } else if let userProfile = profileViewModel.userProfile {
                        ViewUserProfileView(userProfile: userProfile)
                    } else if profileViewModel.errorMessage != nil {
                         Text("Error: \(profileViewModel.errorMessage ?? "Unknown error")")
                            .foregroundColor(.red)
                            .padding()
                         Button("Retry Load") { profileViewModel.fetchUserProfile() }
                            .foregroundColor(Color.primaryAccentPurple)
                    } else {
                        Text("No profile data available. Try logging out and in.")
                            .foregroundColor(Color.secondaryTextCyan)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackgroundBlack.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline) // Handled by ViewUserProfileView now
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button { showingEditProfile.toggle() } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }

                        Button { authViewModel.signOut() } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                .sheet(isPresented: $showingEditProfile) {
                    // EditProfileView already uses its own ProfileViewModel instance
                    EditProfileView()
                }
            }
            .onAppear {
                // Pass locationService to profileViewModel when the view appears
                // and profileViewModel is ready.
                profileViewModel.setup(locationService: locationService)
                // Also, if current user's profile is needed by LocationService immediately,
                // ensure it's passed. ProfileViewModel's setup now handles this.
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    authViewModel.signOut()
                }
                .padding()
                .background(Color.highlightPurple)
                .foregroundColor(Color.primaryTextWhite)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackgroundBlack.ignoresSafeArea())
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        // Note: .accentColor on TabView is deprecated for controlling tab item color in iOS 16+.
        // The UITabBarAppearance method used in RootView's onAppear is the modern way.
        // However, .tint() or .accentColor() can still influence other elements within the tabs.
        .tint(Color.primaryAccentPurple) // General tint for controls within tabs
    }
}
