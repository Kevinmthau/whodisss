import SwiftUI
import PhotosUI
import Contacts

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
    let contactInfo: ContactInfo
    let viewModel: ContactsViewModel
    @StateObject private var detailViewModel: ContactDetailViewModel
    @State private var activeSheet: ActiveSheet?
    
    init(contactInfo: ContactInfo, viewModel: ContactsViewModel) {
        self.contactInfo = contactInfo
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .imageSearch:
                ImageSearchView(
                    contactName: contactInfo.displayName,
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
            
            Text(contactInfo.displayName)
                .font(.title2)
                .fontWeight(.semibold)
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

#Preview {
    NavigationView {
        ContactDetailView(
            contactInfo: .preview,
            viewModel: ContactsViewModel()
        )
    }
}