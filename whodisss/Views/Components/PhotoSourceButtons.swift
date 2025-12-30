import SwiftUI
import PhotosUI

struct PhotoSourceButtons: View {
    let onSearchGoogle: () -> Void
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ActionButton(
                title: "Search Google Images",
                icon: "magnifyingglass",
                color: .blue,
                action: onSearchGoogle
            )

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose from Photo Library")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            ActionButton(
                title: "Take Photo",
                icon: "camera",
                color: .orange,
                action: onTakePhoto
            )
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

#Preview {
    PhotoSourceButtons(
        onSearchGoogle: {},
        photoPickerItem: .constant(nil),
        onTakePhoto: {}
    )
    .padding()
}
