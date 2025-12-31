import SwiftUI
import PhotosUI

struct FloatingPhotoButton: View {
    let onSearchGoogle: () -> Void
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        Menu {
            Button(action: onSearchGoogle) {
                Label("Search Google Images", systemImage: "magnifyingglass")
            }

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
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
    }
}

#Preview {
    FloatingPhotoButton(
        onSearchGoogle: {},
        photoPickerItem: .constant(nil),
        onTakePhoto: {}
    )
}
