import SwiftUI
import PhotosUI
import Contacts
import ContactsUI

struct ContactDetailView: View {
    @State private var contactInfo: ContactInfo
    let viewModel: ContactsViewModel
    @StateObject private var detailViewModel: ContactDetailViewModel
    @StateObject private var sheetCoordinator = SheetCoordinator()
    @State private var showContactEditor = false

    init(contactInfo: ContactInfo, viewModel: ContactsViewModel) {
        self._contactInfo = State(initialValue: contactInfo)
        self.viewModel = viewModel
        self._detailViewModel = StateObject(wrappedValue: ContactDetailViewModel(
            contactInfo: contactInfo,
            contactsViewModel: viewModel
        ))
    }

    var body: some View {
        VStack(spacing: 30) {
            ContactHeaderView(contactInfo: contactInfo)

            PhotoSourceButtons(
                onSearchGoogle: { sheetCoordinator.present(.imageSearch) },
                photoPickerItem: $detailViewModel.photoPickerItem,
                onTakePhoto: { sheetCoordinator.present(.camera) }
            )
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showContactEditor = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(item: $sheetCoordinator.activeSheet, onDismiss: {
            sheetCoordinator.handleSheetDismissed()
        }) { sheet in
            switch sheet {
            case .imageSearch:
                ImageSearchView(
                    contactName: contactInfo.displayName,
                    companyName: contactInfo.contact.organizationName.isEmpty ? nil : contactInfo.contact.organizationName,
                    onImageSelected: { image in
                        detailViewModel.handleImageSearchSelection(image)
                        sheetCoordinator.transitionTo(.photoEditor)
                    }
                )
            case .camera:
                CameraView(onImageCaptured: { image in
                    detailViewModel.handleCameraCapture(image)
                    sheetCoordinator.transitionTo(.photoEditor)
                })
            case .photoEditor:
                if let image = detailViewModel.selectedImage {
                    PhotoEditorView(originalImage: image) { editedImage in
                        Task {
                            await detailViewModel.saveEditedImage(editedImage)
                            sheetCoordinator.dismiss()
                        }
                    }
                }
            }
        }
        .onChange(of: detailViewModel.photoPickerItem) { _, _ in
            Task {
                await detailViewModel.processPhotoPickerItem()
                if detailViewModel.selectedImage != nil {
                    sheetCoordinator.present(.photoEditor)
                }
            }
        }
        .overlay {
            if detailViewModel.isSaving {
                SavingOverlay()
            }
        }
        .sheet(isPresented: $showContactEditor) {
            ContactEditorWrapper(contact: contactInfo.contact, isPresented: $showContactEditor) { updatedContact in
                if let updatedContact = updatedContact {
                    // Update the local contact info with the edited contact
                    contactInfo = ContactInfo(contact: updatedContact, hasImage: updatedContact.imageDataAvailable)
                    // Don't refresh the entire contacts list to avoid navigation issues
                    // The contact will be updated when returning to the list naturally
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ContactDetailView(
            contactInfo: .preview,
            viewModel: ContactsViewModel()
        )
    }
}
