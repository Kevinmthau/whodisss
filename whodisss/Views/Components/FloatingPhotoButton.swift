import SwiftUI
import PhotosUI
import UIKit

struct FloatingPhotoButton: View {
    let onSearchGoogle: () -> Void
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void
    let onDeleteContact: () -> Void

    @State private var showActions = false
    @State private var showPhotoPicker = false
    @State private var pendingAction: PendingAction?

    private enum PendingAction {
        case searchGoogle
        case chooseFromLibrary
        case takePhoto
        case deleteContact
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Button {
            showActions = true
        } label: {
            Image(systemName: "camera.badge.ellipsis")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .confirmationDialog("Contact Actions", isPresented: $showActions, titleVisibility: .visible) {
            Button(action: { pendingAction = .searchGoogle }) {
                Label("Search Google Images", systemImage: "magnifyingglass")
            }

            Button(action: { pendingAction = .chooseFromLibrary }) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }

            Button(action: { pendingAction = .takePhoto }) {
                Label("Take Photo", systemImage: "camera")
            }
            .disabled(!isCameraAvailable)

            Button("Delete Contact", role: .destructive) {
                pendingAction = .deleteContact
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: showActions) { _, isPresented in
            guard !isPresented, let pendingAction else { return }
            self.pendingAction = nil

            switch pendingAction {
            case .searchGoogle:
                onSearchGoogle()
            case .chooseFromLibrary:
                showPhotoPicker = true
            case .takePhoto:
                onTakePhoto()
            case .deleteContact:
                onDeleteContact()
            }
        }
    }
}

#Preview {
    FloatingPhotoButton(
        onSearchGoogle: {},
        photoPickerItem: .constant(nil),
        onTakePhoto: {},
        onDeleteContact: {}
    )
}
