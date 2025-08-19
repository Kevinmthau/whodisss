import Foundation
import SwiftUI
import PhotosUI

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var photoPickerItem: PhotosPickerItem?
    @Published var isSaving = false
    
    let contactInfo: ContactInfo
    private let contactsViewModel: ContactsViewModel
    private let imageService: ImageServiceProtocol
    
    init(
        contactInfo: ContactInfo,
        contactsViewModel: ContactsViewModel,
        imageService: ImageServiceProtocol = ImageService()
    ) {
        self.contactInfo = contactInfo
        self.contactsViewModel = contactsViewModel
        self.imageService = imageService
    }
    
    func handleImageSearchSelection(_ image: UIImage) {
        selectedImage = image
    }
    
    func handleCameraCapture(_ image: UIImage) {
        selectedImage = image
    }
    
    func processPhotoPickerItem() async {
        guard let item = photoPickerItem else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            print("Failed to load image from photo picker: \(error)")
        }
        
        photoPickerItem = nil
    }
    
    func saveEditedImage(_ editedImage: UIImage) async {
        isSaving = true
        defer { isSaving = false }
        
        let success = await contactsViewModel.saveImageToContact(
            contactInfo.contact,
            image: editedImage
        )
        
        if success {
            selectedImage = nil
        }
    }
}