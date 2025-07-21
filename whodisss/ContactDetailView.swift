import SwiftUI
import PhotosUI
import Contacts

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ContactDetailView: View {
    let contactInfo: ContactInfo
    let dataManager: ContactDataManager
    
    @State private var showingImageSearch = false
    @State private var showingPhotoLibrary = false
    @State private var showingCamera = false
    @State private var showingPhotoEditor = false
    @State private var selectedImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isSaving = false
    @State private var pendingPhotoEditor = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Group {
                    if let image = contactInfo.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
                
                VStack {
                    Text(contactInfo.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if !contactInfo.hasImage {
                        Text("No profile photo")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    showingImageSearch = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search Google Images")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
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
                
                Button(action: {
                    showingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Add Photo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImageSearch) {
            ImageSearchView(contactName: contactInfo.displayName) { image in
                selectedImage = image
                pendingPhotoEditor = true
            }
        }
        .onChange(of: showingImageSearch) { _, isShowing in
            if !isShowing && pendingPhotoEditor {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingPhotoEditor = true
                    pendingPhotoEditor = false
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                selectedImage = image
                showingPhotoEditor = true
            }
        }
        .sheet(isPresented: $showingPhotoEditor) {
            if let image = selectedImage {
                PhotoEditorView(originalImage: image) { editedImage in
                    Task {
                        isSaving = true
                        let success = await dataManager.saveImageToContact(contactInfo.contact, image: editedImage)
                        isSaving = false
                        
                        if success {
                            showingPhotoEditor = false
                            selectedImage = nil
                        }
                    }
                }
            }
        }
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    showingPhotoEditor = true
                }
                photoPickerItem = nil
            }
        }
        .overlay {
            if isSaving {
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
    }
}

#Preview {
    NavigationView {
        ContactDetailView(
            contactInfo: ContactInfo(
                contact: CNContact(),
                hasImage: false
            ),
            dataManager: ContactDataManager()
        )
    }
}