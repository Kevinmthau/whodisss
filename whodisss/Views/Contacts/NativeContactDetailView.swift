import SwiftUI
import PhotosUI
import Contacts
import UIKit

struct NativeContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contactInfo: ContactInfo
    @State private var contactVersion = 0
    @State private var showingDeleteConfirmation = false
    let viewModel: ContactsViewModel
    @StateObject private var detailViewModel: ContactDetailViewModel
    @StateObject private var sheetCoordinator = SheetCoordinator()

    init(contactInfo: ContactInfo, viewModel: ContactsViewModel) {
        self._contactInfo = State(initialValue: contactInfo)
        self.viewModel = viewModel
        self._detailViewModel = StateObject(wrappedValue: ContactDetailViewModel(
            contactsViewModel: viewModel
        ))
    }

    var body: some View {
        ZStack {
            ContactViewControllerRepresentable(
                contact: contactInfo.contact,
                onBack: { dismiss() },
                onDeleteTapped: {
                    guard !detailViewModel.isDeleting else { return }
                    showingDeleteConfirmation = true
                },
                onContactUpdated: { updatedContact in
                    contactInfo = ContactInfo(
                        contact: updatedContact,
                        hasImage: ContactInfo.hasImage(for: updatedContact)
                    )
                }
            )
            .id(contactVersion)
            .ignoresSafeArea()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingPhotoButton(
                        onSearchGoogle: { sheetCoordinator.present(.imageSearch) },
                        photoPickerItem: $detailViewModel.photoPickerItem,
                        onTakePhoto: {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                sheetCoordinator.present(.camera)
                            } else {
                                detailViewModel.showErrorMessage("Camera is not available on this device")
                            }
                        }
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $sheetCoordinator.activeSheet, onDismiss: {
            sheetCoordinator.handleSheetDismissed()
        }) { sheet in
            ContactDetailSheetContent(
                sheet: sheet,
                contactInfo: contactInfo,
                detailViewModel: detailViewModel,
                sheetCoordinator: sheetCoordinator,
                onPhotoSaved: { contactVersion += 1 }
            )
        }
        .confirmationDialog("Delete Contact?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Contact", role: .destructive) {
                Task {
                    if await detailViewModel.deleteContact(contactInfo.contact) {
                        dismiss()
                    }
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This contact will be removed from your contacts.")
        }
        .onChange(of: detailViewModel.photoPickerItem) { _, _ in
            Task {
                if let _ = await detailViewModel.processPhotoPickerItem() {
                    sheetCoordinator.present(.photoEditor)
                }
            }
        }
        .overlay {
            if detailViewModel.isSaving || detailViewModel.isDeleting {
                SavingOverlay(detailViewModel.isDeleting ? "Deleting contact..." : "Saving photo...")
            }
        }
        .errorAlert(for: detailViewModel)
    }
}

#Preview {
    NavigationView {
        NativeContactDetailView(
            contactInfo: .preview,
            viewModel: ContactsViewModel()
        )
    }
}
