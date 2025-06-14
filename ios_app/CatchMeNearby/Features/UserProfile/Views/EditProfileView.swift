import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                if viewModel.isLoading && viewModel.userProfile == nil {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .listRowBackground(Color.primaryBackgroundBlack)
                } else {
                    Section(header: Text("Public Information").foregroundColor(.secondaryTextCyan)) {
                        TextField("Username", text: $viewModel.username)
                            .foregroundColor(Color.primaryTextWhite) // For TextField text color
                            .modifier(ClearButton(text: $viewModel.username))

                        // TextEditor needs a bit more handling for placeholder and height
                        ZStack(alignment: .topLeading) {
                            if viewModel.bio.isEmpty {
                                Text("Tell us about yourself...")
                                    .foregroundColor(Color.gray.opacity(0.6))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            TextEditor(text: $viewModel.bio)
                                .frame(minHeight: 100, maxHeight: 200)
                                .foregroundColor(Color.primaryTextWhite) // For TextEditor text color
                        }
                    }
                    .listRowBackground(Color.secondaryBackgroundDarkGray)
                    .foregroundColor(Color.primaryTextWhite) // For Section text color

                    Section(header: Text("Photos (Max 7)").foregroundColor(.secondaryTextCyan)) {
                        List {
                            ForEach(viewModel.photoItems, id: \.self) { itemURL in
                                // In a real app, use AsyncImage (iOS 15+) or a library to load images
                                HStack {
                                    // Placeholder for an image
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color.secondaryTextCyan)
                                    Text(itemURL.split(separator: "/").last?.split(separator: "?").first.map(String.init) ?? "Photo")
                                        .foregroundColor(Color.primaryTextWhite)
                                }
                            }
                            .onDelete(perform: viewModel.removePhoto)

                            if viewModel.photoItems.count < 7 {
                                Button(action: {
                                    // In a real app, this would present an ImagePicker
                                    viewModel.addPhoto(placeholderURL: "user_photos/placeholder_image_\(Int.random(in: 100...999)).jpg")
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Photo (Placeholder)")
                                    }
                                }
                                .foregroundColor(Color.primaryAccentPurple)
                            }
                        }
                    }
                    .listRowBackground(Color.secondaryBackgroundDarkGray)


                    Section(header: Text("Settings").foregroundColor(.secondaryTextCyan)) {
                        Toggle("Enable Location Sharing", isOn: $viewModel.locationSharingEnabled)
                            .foregroundColor(Color.primaryTextWhite) // For Toggle label color
                    }
                    .listRowBackground(Color.secondaryBackgroundDarkGray)

                    if viewModel.isLoading && viewModel.userProfile != nil { // Show loading indicator during save
                        Section {
                            ProgressView().frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(Color.primaryBackgroundBlack)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Section {
                            Text(errorMessage).foregroundColor(.red).font(.caption)
                        }
                        .listRowBackground(Color.primaryBackgroundBlack)
                    }
                }
            }
            .background(Color.primaryBackgroundBlack.ignoresSafeArea()) // Form background
            .scrollContentBackground(.hidden) // Make Form use its own background for rows
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.primaryAccentPurple)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveProfile()
                    }
                    .foregroundColor(Color.primaryAccentPurple)
                    .disabled(viewModel.isLoading)
                }
            }
            .accentColor(Color.primaryAccentPurple) // General accent for toolbar, etc.
            .onChange(of: viewModel.saveSuccess) { success in
                if success {
                    dismiss() // Dismiss on successful save
                }
            }
            // .onAppear {
            //    // ViewModel already fetches in init if currentUserID is available
            //    // If profile might be nil due to auth delay, consider re-fetching here
            //    // or ensuring init fetch is robust against it.
            // }
        }
        // Apply the app's global tint to the NavigationView itself
        .tint(Color.primaryAccentPurple)
    }
}

// Helper for TextField clear button
struct ClearButton: ViewModifier {
    @Binding var text: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(Color.gray.opacity(0.7))
                }
                .padding(.trailing, 8)
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .preferredColorScheme(.dark) // For previewing in dark mode
    }
}
