import Foundation
import SwiftUI
import PhotosUI
import Contacts

@MainActor
class ContactDetailViewModel: ObservableObject, ErrorHandling {
    @Published var selectedImage: UIImage?
    @Published var photoPickerItem: PhotosPickerItem?
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let contactsViewModel: ContactsViewModel

    init(contactsViewModel: ContactsViewModel) {
        self.contactsViewModel = contactsViewModel
    }

    func handleImageSearchSelection(_ image: UIImage) {
        selectedImage = image
    }

    func handleCameraCapture(_ image: UIImage) {
        selectedImage = image
    }

    func processPhotoPickerItem() async -> UIImage? {
        guard let item = photoPickerItem else { return nil }

        defer { photoPickerItem = nil }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                return image
            }
        } catch {
            handleError(error, message: "Failed to load image from photo picker")
        }

        return nil
    }

    func saveEditedImage(_ editedImage: UIImage, for contact: CNContact) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        let success = await contactsViewModel.saveImageToContact(
            contact,
            image: editedImage
        )

        if success {
            selectedImage = nil
        }

        return success
    }
}
