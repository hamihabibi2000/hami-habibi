import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    // State for showing an edit profile sheet or navigation
    @State private var showingEditProfile = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authViewModel.currentUser {
                    // Profile Picture Placeholder
                    // In a later step, this will load the image from user.profilePhotoUrl
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .padding(.top, 40)

                    Text(user.username)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // Placeholder for future content like user's posts, stats, etc.
                    // List {
                    //     Text("My Posts (Coming Soon)")
                    //     Text("Account Settings (Coming Soon)")
                    // }

                    Spacer()

                    Button("Edit Profile") {
                        showingEditProfile = true
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)

                    Button("Log Out") {
                        authViewModel.signOut()
                    }
                    .padding()
                    .foregroundColor(.red)

                } else {
                    Text("Loading profile...")
                    // Or show a login/signup prompt if no user session and currentUser is nil
                    // This view should typically only be accessed when a user is logged in.
                }
            }
            .padding()
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditProfile) {
                // EditProfileView will be created in a subsequent step
                // For now, a placeholder:
                EditProfileView().environmentObject(authViewModel)
            }
            .onAppear {
                if authViewModel.userSession != nil && authViewModel.currentUser == nil {
                    // If there's a session but no user data, try fetching it.
                    // This can happen if the app was closed and reopened.
                    authViewModel.fetchUser(uid: authViewModel.userSession!.uid)
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Mocking a logged-in user for preview
        let mockAuthViewModel = AuthViewModel()
        // It's tricky to set userSession and currentUser directly for preview
        // without actual Firebase interaction or more complex mocking.
        // For a basic preview, this is okay. For a data-filled preview,
        // you might initialize currentUser with mock data.
        // Example:
        // mockAuthViewModel.currentUser = User(id: "mockID", username: "PreviewUser", email: "preview@example.com", profilePhotoUrl: nil, createdAt: Timestamp(), updatedAt: Timestamp())

        ProfileView().environmentObject(mockAuthViewModel)
    }
}
