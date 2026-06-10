import SwiftUI
import Contacts

struct ContactDetailSheetContent: View {
    let sheet: ActiveSheet
    let contactInfo: ContactInfo
    @ObservedObject var detailViewModel: ContactDetailViewModel
    @ObservedObject var sheetCoordinator: SheetCoordinator
    let onPhotoSaved: () -> Void

    var body: some View {
        switch sheet {
        case .imageSearch:
            ImageSearchView(
                contactName: contactInfo.displayName,
                companyName: contactInfo.companyName,
                location: contactInfo.locationString,
                onImageSelected: { image in
                    detailViewModel.handleImageSearchSelection(image)
                    sheetCoordinator.transitionTo(.photoEditor)
                }
            )
        case .camera:
            CameraView(
                onImageCaptured: { image in
                    detailViewModel.handleCameraCapture(image)
                    sheetCoordinator.transitionTo(.photoEditor)
                },
                onUnavailable: {
                    detailViewModel.showErrorMessage("Camera is not available on this device")
                    sheetCoordinator.dismiss()
                }
            )
        case .photoEditor:
            if let image = detailViewModel.selectedImage {
                PhotoEditorView(originalImage: image) { editedImage in
                    Task {
                        if await detailViewModel.saveEditedImage(editedImage, for: contactInfo.contact) {
                            sheetCoordinator.dismiss()
                            onPhotoSaved()
                        }
                    }
                }
            }
        }
    }
}
