import SwiftUI
import PhotosUI
import Contacts
import ContactsUI

enum ActiveSheet: Identifiable {
    case imageSearch
    case camera
    case photoEditor
    
    var id: Int {
        switch self {
        case .imageSearch: return 0
        case .camera: return 1
        case .photoEditor: return 2
        }
    }
}

struct ContactDetailView: View {
    @State private var contactInfo: ContactInfo
    let viewModel: ContactsViewModel
    @StateObject private var detailViewModel: ContactDetailViewModel
    @State private var activeSheet: ActiveSheet?
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
                onSearchGoogle: { activeSheet = .imageSearch },
                photoPickerItem: $detailViewModel.photoPickerItem,
                onTakePhoto: { activeSheet = .camera }
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .imageSearch:
                ImageSearchView(
                    contactName: contactInfo.displayName,
                    companyName: contactInfo.contact.organizationName.isEmpty ? nil : contactInfo.contact.organizationName,
                    onImageSelected: { image in
                        detailViewModel.handleImageSearchSelection(image)
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if detailViewModel.selectedImage != nil {
                                activeSheet = .photoEditor
                            }
                        }
                    }
                )
            case .camera:
                CameraView(onImageCaptured: { image in
                    detailViewModel.handleCameraCapture(image)
                    activeSheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if detailViewModel.selectedImage != nil {
                            activeSheet = .photoEditor
                        }
                    }
                })
            case .photoEditor:
                if let image = detailViewModel.selectedImage {
                    PhotoEditorView(originalImage: image) { editedImage in
                        Task {
                            await detailViewModel.saveEditedImage(editedImage)
                            activeSheet = nil
                        }
                    }
                }
            }
        }
        .onChange(of: detailViewModel.photoPickerItem) { _, _ in
            Task {
                await detailViewModel.processPhotoPickerItem()
                if detailViewModel.selectedImage != nil {
                    activeSheet = .photoEditor
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

struct ContactHeaderView: View {
    let contactInfo: ContactInfo

    var body: some View {
        VStack(spacing: 20) {
            ContactAvatarView(contactInfo: contactInfo, size: 120)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )

            VStack(spacing: 4) {
                Text(contactInfo.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if !contactInfo.contact.organizationName.isEmpty {
                    Text(contactInfo.contact.organizationName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

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

struct SavingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving photo...")
                    .padding(.top)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

struct ContactEditorWrapper: UIViewControllerRepresentable {
    let contact: CNContact
    @Binding var isPresented: Bool
    let onDismiss: (CNContact?) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        // Fetch contact with all required keys for CNContactViewController
        let store = CNContactStore()
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]

        guard let fullContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch) else {
            // If we can't fetch the full contact, create a basic view controller
            let controller = CNContactViewController()
            return UINavigationController(rootViewController: controller)
        }

        let controller = CNContactViewController(for: fullContact)
        controller.allowsEditing = true
        controller.allowsActions = false
        controller.delegate = context.coordinator

        // Add Cancel button
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: context.coordinator, action: #selector(Coordinator.cancelTapped))
        controller.navigationItem.leftBarButtonItem = cancelButton

        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactEditorWrapper

        init(_ parent: ContactEditorWrapper) {
            self.parent = parent
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.onDismiss(contact)
            parent.isPresented = false
        }

        @objc func cancelTapped() {
            parent.onDismiss(nil)
            parent.isPresented = false
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