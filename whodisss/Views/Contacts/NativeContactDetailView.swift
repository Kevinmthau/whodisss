import SwiftUI
import PhotosUI
import Contacts
import ContactsUI

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
            contactInfo: contactInfo,
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
                        hasImage: updatedContact.imageDataAvailable
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
                        onTakePhoto: { sheetCoordinator.present(.camera) }
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
                            // Increment version to refresh the native contact view with new photo
                            contactVersion += 1
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
    }
}

struct ContactViewControllerRepresentable: UIViewControllerRepresentable {
    let contact: CNContact
    let onBack: () -> Void
    let onContactUpdated: (CNContact) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]

        guard let fullContact = try? store.unifiedContact(
            withIdentifier: contact.identifier,
            keysToFetch: keysToFetch
        ) else {
            let emptyController = UIViewController()
            emptyController.view.backgroundColor = .systemBackground
            return UINavigationController(rootViewController: emptyController)
        }

        let controller = CNContactViewController(for: fullContact)
        controller.allowsEditing = true
        controller.allowsActions = true
        controller.delegate = context.coordinator

        // Add back button that dismisses to SwiftUI
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.backTapped)
        )
        controller.navigationItem.leftBarButtonItem = backButton

        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        context.coordinator.onBack = onBack
        context.coordinator.onContactUpdated = onContactUpdated
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBack: onBack, onContactUpdated: onContactUpdated)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var onContactUpdated: (CNContact) -> Void
        var onBack: () -> Void

        init(onBack: @escaping () -> Void, onContactUpdated: @escaping (CNContact) -> Void) {
            self.onBack = onBack
            self.onContactUpdated = onContactUpdated
        }

        @objc func backTapped() {
            onBack()
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            if let contact = contact {
                onContactUpdated(contact)
            }
        }
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
