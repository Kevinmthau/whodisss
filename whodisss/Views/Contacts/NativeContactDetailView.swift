import SwiftUI
import PhotosUI
import Contacts
import UIKit

struct NativeContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contactInfo: ContactInfo
    @State private var contactVersion = 0
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
        .onChange(of: detailViewModel.photoPickerItem) { _, _ in
            Task {
                if let _ = await detailViewModel.processPhotoPickerItem() {
                    sheetCoordinator.present(.photoEditor)
                }
            }
        }
        .overlay {
            if detailViewModel.isSaving {
                SavingOverlay()
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
