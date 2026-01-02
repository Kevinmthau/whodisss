import SwiftUI
import PhotosUI

struct FloatingPhotoButton: View {
    let onSearchGoogle: () -> Void
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    @State private var showPhotoPicker = false

    var body: some View {
        Menu {
            Button(action: onSearchGoogle) {
                Label("Search Google Images", systemImage: "magnifyingglass")
            }

            Button(action: { showPhotoPicker = true }) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }

            Button(action: onTakePhoto) {
                Label("Take Photo", systemImage: "camera")
            }
        } label: {
            Image(systemName: "camera.badge.ellipsis")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
    }
}

#Preview {
    FloatingPhotoButton(
        onSearchGoogle: {},
        photoPickerItem: .constant(nil),
        onTakePhoto: {}
    )
}
