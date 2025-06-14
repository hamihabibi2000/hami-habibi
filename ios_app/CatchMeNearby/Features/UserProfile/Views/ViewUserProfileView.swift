import SwiftUI

struct ViewUserProfileView: View {
    // This view can be initialized with a UserProfile object directly,
    // or with a userID to fetch the profile if needed.
    // For this example, it receives a UserProfile object.
    let userProfile: UserProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo Gallery (Horizontal ScrollView of Placeholders)
                if let photoURLs = userProfile.photoURLs, !photoURLs.isEmpty {
                    Text("Photos")
                        .font(.title2).bold()
                        .foregroundColor(.primaryAccentPurple)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(photoURLs, id: \.self) { photoURL in
                                // Placeholder for actual image loading (e.g., AsyncImage for iOS 15+)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondaryBackgroundDarkGray)
                                        .frame(width: 150, height: 200)
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)

                                    Image(systemName: "photo.on.rectangle.angled") // Placeholder icon
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.secondaryTextCyan.opacity(0.7))

                                    VStack {
                                        Spacer()
                                        Text(photoURL.split(separator: "/").last?.split(separator: "?").first.map(String.init) ?? "Photo")
                                            .font(.caption)
                                            .foregroundColor(.primaryTextWhite.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding(5)
                                            .background(Color.black.opacity(0.4))
                                            .cornerRadius(5)
                                    }
                                    .padding(5)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 210) // Set a fixed height for the scroll view content
                    }
                } else {
                    Text("No photos yet.")
                        .font(.headline)
                        .foregroundColor(.secondaryTextCyan)
                        .padding(.horizontal)
                        .frame(height: 210) // Match height for consistency
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.secondaryBackgroundDarkGray.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                // Username
                Text(userProfile.username)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryTextWhite)
                    .padding(.horizontal)
                    .padding(.top, 10)

                // Bio
                if let bio = userProfile.bio, !bio.isEmpty {
                    Text("Bio")
                        .font(.title3).bold()
                        .foregroundColor(.primaryAccentPurple)
                        .padding(.horizontal)
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.primaryTextWhite)
                        .padding(.horizontal)
                        .lineLimit(nil) // Allow multiple lines for bio
                } else {
                    Text("No bio provided.")
                        .font(.headline)
                        .foregroundColor(.secondaryTextCyan)
                        .padding(.horizontal)
                }

                // Example of other info
                VStack(alignment: .leading) {
                    Text("Details")
                        .font(.title3).bold()
                        .foregroundColor(.primaryAccentPurple)

                    HStack {
                        Image(systemName: userProfile.locationSharingEnabled ? "location.fill" : "location.slash.fill")
                        Text("Location Sharing: \(userProfile.locationSharingEnabled ? "Enabled" : "Disabled")")
                    }
                    .foregroundColor(userProfile.locationSharingEnabled ? Color.green.opacity(0.8) : Color.red.opacity(0.8))

                    HStack {
                        Image(systemName: userProfile.isPremiumUser ? "star.fill" : "star")
                        Text("Account: \(userProfile.isPremiumUser ? "Premium" : "Standard")")
                    }
                    .foregroundColor(userProfile.isPremiumUser ? Color.yellow.opacity(0.8) : Color.secondaryTextCyan)

                    if let createdAt = userProfile.createdAt {
                         HStack {
                            Image(systemName: "calendar")
                            Text("Joined: \(createdAt.dateValue(), style: .date)")
                        }
                        .foregroundColor(.secondaryTextCyan)
                    }
                }
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.top, 10)


                Spacer() // Pushes content to the top
            }
            .padding(.vertical)
        }
        .background(Color.primaryBackgroundBlack.ignoresSafeArea())
        .navigationTitle(userProfile.username)
        .navigationBarTitleDisplayMode(.inline)
        // Use system font as per earlier decision
    }
}

// Preview provider
struct ViewUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample UserProfile for previewing
        let sampleUser = UserProfile(
            id: "sampleUID123",
            username: "CyberViolet",
            bio: "Lover of all things purple and futuristic. Catch me if you can!",
            photoURLs: ["url1/photo.jpg", "url2/another.png", "url3/image.jpeg"],
            locationSharingEnabled: true,
            isPremiumUser: true,
            createdAt: Timestamp(date: Date())
        )

        NavigationView {
            ViewUserProfileView(userProfile: sampleUser)
                .preferredColorScheme(.dark)
        }
    }
}
