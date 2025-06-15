import SwiftUI
import PhotosUI
import AVFoundation // For video duration and thumbnails (conceptual for now for duration)

struct CreatePostView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var postViewModel = PostViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var caption: String = ""
    // Use a single type to manage selected items better for photo OR video logic
    @State private var selectedPickerItems: [PhotosPickerItem] = []

    @State private var mediaForUpload: [PostViewModel.MediaItem] = []
    @State private var previewImages: [Image] = [] // For photo previews
    @State private var videoPreviewImage: Image? // For video thumbnail
    @State private var selectedVideoURL: URL? // For potential local playback if needed (not for MVP upload)

    @State private var showingMediaPicker = false
    @State private var isUploading = false
    @State private var currentMediaType: PostViewModel.MediaType? = nil // To enforce photo OR video

    let maxPhotos = 5
    let videoDurationLimit: Double = 60.0 // seconds

    var body: some View {
        NavigationView {
            VStack {
                if isUploading {
                    ProgressView("Uploading...")
                    Spacer()
                } else {
                    Form {
                        Section(header: Text("Caption (Optional)")) {
                            TextEditor(text: $caption)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }

                        Section(header: Text(sectionHeaderTitle())) {
                            if currentMediaType == .photo && !previewImages.isEmpty {
                                photoPreviewGrid()
                            } else if currentMediaType == .video && videoPreviewImage != nil {
                                videoPreview()
                            }

                            if canSelectMoreMedia() {
                                Button {
                                    showingMediaPicker = true
                                } label: {
                                    Label(buttonLabelTitle(), systemImage: "photo.on.rectangle.angled")
                                }
                            } else if currentMediaType == .photo {
                                Text("Maximum \(maxPhotos) photos reached.")
                                    .font(.caption).foregroundColor(.gray)
                            } else if currentMediaType == .video {
                                 Text("Video selected. Only one video allowed.")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }

                        if let errorMessage = postViewModel.errorMessage {
                            Text(errorMessage).foregroundColor(.red).font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") { handlePostCreation() }
                    .disabled(mediaForUpload.isEmpty || isUploading)
                }
            }
            .sheet(isPresented: $showingMediaPicker) {
                if #available(iOS 16.0, *) {
                    PhotosPicker(
                        selection: $selectedPickerItems,
                        maxSelectionCount: currentMediaType == .video ? 1 : (maxPhotos - mediaForUpload.count),
                        matching: currentMediaType == .video ? .videos : (currentMediaType == .photo ? .images : .any(of: [.images, .videos]))
                    )
                    .onChange(of: selectedPickerItems, perform: processSelectedItems)
                } else {
                    Text("Media picker requires iOS 16+. (Placeholder for older OS support)")
                }
            }
        }
    }

    @ViewBuilder
    private func photoPreviewGrid() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(previewImages.indices, id: \.self) { index in
                    previewImages[index]
                        .resizable().scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(removeButtonOverlay(action: { removeMedia(at: index, type: .photo) }))
                }
            }
        }
        .frame(height: 110)
    }

    @ViewBuilder
    private func videoPreview() -> some View {
        if let videoPreviewImage = videoPreviewImage {
            videoPreviewImage
                .resizable().scaledToFill()
                .frame(width: 150, height: 100) // Aspect ratio might vary
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(removeButtonOverlay(action: { removeMedia(at: 0, type: .video) }))
        }
    }

    @ViewBuilder
    private func removeButtonOverlay(action: @escaping () -> Void) -> some View {
        Image(systemName: "xmark.circle.fill")
            .foregroundColor(.white).background(Color.black.opacity(0.6)).clipShape(Circle())
            .padding(5)
            .contentShape(Rectangle()) // Make whole area tappable for the button
            .onTapGesture(perform: action)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func sectionHeaderTitle() -> String {
        if currentMediaType == .photo {
            return "Add Photos (\(mediaForUpload.count)/\(maxPhotos))"
        } else if currentMediaType == .video {
            return "Add Video (1/1)"
        }
        return "Add Media"
    }

    private func buttonLabelTitle() -> String {
        if currentMediaType == .photo || currentMediaType == nil {
            return "Select Photos"
        }
        return "Select Video"
    }

    private func canSelectMoreMedia() -> Bool {
        if currentMediaType == .photo {
            return mediaForUpload.count < maxPhotos
        } else if currentMediaType == .video {
            return mediaForUpload.isEmpty // Only one video
        }
        return mediaForUpload.isEmpty // If type not yet determined, can select
    }

    @available(iOS 16.0, *)
    private func processSelectedItems(newItems: [PhotosPickerItem]) {
        Task {
            // If currentMediaType is not set, the first item determines the type for this post.
            if currentMediaType == nil, let firstItem = newItems.first {
                if firstItem.supportedContentTypes.contains(.image) {
                    currentMediaType = .photo
                } else if firstItem.supportedContentTypes.first(where: { $0.conforms(to: .video) || $0.conforms(to: .movie) }) != nil {
                    currentMediaType = .video
                }
            }

            var loadedMedia: [PostViewModel.MediaItem] = []
            var loadedPreviews: [Image] = [] // For photos
            var loadedVideoPreview: Image? = nil // For video

            for item in newItems {
                if currentMediaType == .photo && mediaForUpload.count + loadedMedia.count < maxPhotos {
                    if item.supportedContentTypes.contains(.image) {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            let compressedData = uiImage.jpegData(compressionQuality: 0.7) ?? data
                            loadedMedia.append(PostViewModel.MediaItem(type: .photo, data: compressedData, fileExtension: "jpg"))
                            loadedPreviews.append(Image(uiImage: uiImage))
                        }
                    }
                } else if currentMediaType == .video && mediaForUpload.isEmpty && loadedMedia.isEmpty { // Only one video
                     if item.supportedContentTypes.first(where: { $0.conforms(to: .video) || $0.conforms(to: .movie) }) != nil {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            // Video duration check is complex here. Would typically involve saving to temp file
                            // and using AVAsset. For MVP, we might have to skip strict client-side duration check
                            // or make it a post-upload validation (less ideal).
                            // For now, assume it's okay or < 60s based on brief.

                            // Create a generic video preview
                            loadedVideoPreview = Image(systemName: "video.circle.fill") // Placeholder
                            // TODO: Attempt to generate a real thumbnail if possible (AVAssetImageGenerator)

                            loadedMedia.append(PostViewModel.MediaItem(type: .video, data: data, fileExtension: "mp4")) // Assume mp4
                            // Once a video is selected, break as we only allow one.
                            break
                        }
                    }
                }
            }

            // Update state on main thread
            DispatchQueue.main.async {
                if self.currentMediaType == .photo {
                    let availableSlots = self.maxPhotos - self.mediaForUpload.count
                    self.mediaForUpload.append(contentsOf: loadedMedia.prefix(availableSlots))
                    self.previewImages.append(contentsOf: loadedPreviews.prefix(availableSlots))
                } else if self.currentMediaType == .video {
                    self.mediaForUpload.append(contentsOf: loadedMedia.prefix(1)) // Max 1 video
                    self.videoPreviewImage = loadedVideoPreview ?? self.videoPreviewImage
                }
                self.selectedPickerItems = [] // Clear picker selection
            }
        }
    }

    private func removeMedia(at index: Int, type: PostViewModel.MediaType) {
        if type == .photo {
            guard index < mediaForUpload.count && index < previewImages.count else { return }
            // Filter out the photo at the given index (assuming all are photos)
            // This removal logic is a bit naive if mediaForUpload can have mixed types before filtering,
            // but with currentMediaType enforcement, it should mostly contain one type.
            // A more robust way would be to associate an ID with each MediaItem upon selection.
            let photoItems = mediaForUpload.filter { $0.type == .photo }
            if index < photoItems.count {
                let itemToRemove = photoItems[index]
                 // Find the actual item in mediaForUpload to remove, as its index might differ
                 // if mediaForUpload wasn't perfectly clean (which it should be with currentMediaType)
                if let actualIndexInMediaForUpload = mediaForUpload.firstIndex(where: {$0.data == itemToRemove.data}) {
                    mediaForUpload.remove(at: actualIndexInMediaForUpload)
                    previewImages.remove(at: index) // This assumes previewImages directly maps to photoItems
                }
            }

        } else if type == .video {
            mediaForUpload.removeAll()
            videoPreviewImage = nil
            selectedVideoURL = nil
        }
        if mediaForUpload.isEmpty {
            currentMediaType = nil // Reset media type if all items are removed
        }
    }

    private func handlePostCreation() {
        guard let currentUser = authViewModel.currentUser else {
            postViewModel.errorMessage = "Cannot post: User not logged in."
            return
        }
        guard !mediaForUpload.isEmpty else {
            postViewModel.errorMessage = "Please select media to post."
            return
        }
        // Ensure mediaType is set in Post object in PostViewModel
        // The current structure of mediaForUpload has type, so that's good.

        isUploading = true
        postViewModel.uploadPost(caption: caption.isEmpty ? nil : caption, mediaItems: mediaForUpload, user: currentUser) { success in
            isUploading = false
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
