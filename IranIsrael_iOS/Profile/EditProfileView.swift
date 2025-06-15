import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedImage: UIImage?
    @State private var profileImageDisplay: Image?
    @State private var newUsername: String = ""

    @State private var showingImagePicker = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    VStack {
                        Group {
                            if let img = profileImageDisplay {
                                img.resizable().scaledToFill()
                            } else if let existingPhotoUrl = authViewModel.currentUser?.profilePhotoUrl, !existingPhotoUrl.isEmpty {
                                // Use AsyncImage for iOS 15+ to load existing photo
                                if #available(iOS 15.0, *) {
                                    AsyncImage(url: URL(string: existingPhotoUrl)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill").resizable().scaledToFit().foregroundColor(.gray)
                                    }
                                } else {
                                    // Fallback for older iOS versions (placeholder)
                                    Image(systemName: "person.circle.fill").resizable().scaledToFit().foregroundColor(.gray)
                                }
                            } else {
                                Image(systemName: "person.circle.fill").resizable().scaledToFit().foregroundColor(.gray)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                        Button("Change Photo") { showingImagePicker = true }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section(header: Text("Username")) {
                    TextField("Enter new username", text: $newUsername)
                }

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                }

                Button("Save Changes") {
                    isLoading = true
                    let photoChanged = selectedImage != nil
                    let usernameChanged = !newUsername.isEmpty && newUsername != authViewModel.currentUser?.username

                    var tasksToComplete = 0
                    if photoChanged { tasksToComplete += 1 }
                    if usernameChanged { tasksToComplete += 1 }

                    if tasksToComplete == 0 {
                        isLoading = false
                        presentationMode.wrappedValue.dismiss()
                        return
                    }

                    var tasksCompleted = 0
                    let completionHandler = {
                        tasksCompleted += 1
                        if tasksCompleted == tasksToComplete {
                            self.isLoading = false
                            // Ensure user data is fresh
                            if let uid = self.authViewModel.userSession?.uid {
                                self.authViewModel.fetchUser(uid: uid)
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }

                    if photoChanged, let image = selectedImage {
                        authViewModel.updateProfilePhoto(image: image, completion: completionHandler)
                    }

                    if usernameChanged {
                        authViewModel.updateUsername(newUsername: newUsername, completion: completionHandler)
                    }
                }
                .disabled(isLoading || (selectedImage == nil && (newUsername.isEmpty || newUsername == authViewModel.currentUser?.username)))
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImageFromPicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                self.newUsername = authViewModel.currentUser?.username ?? ""
                // If selectedImage is nil and there's a profilePhotoUrl, try to load it via profileImageDisplay or AsyncImage
                // This logic is partially handled by the AsyncImage above.
            }
        }
    }

    func loadImageFromPicker() {
        guard let selectedImage = selectedImage else { return }
        profileImageDisplay = Image(uiImage: selectedImage)
    }
}
