import SwiftUI
import UIKit

struct PhotoEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var croppedImage: UIImage?
    @State private var showingCropEditor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Crop Photo")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Adjust the image to fit as a contact profile photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                    
                    if let croppedImage = croppedImage {
                        Image(uiImage: croppedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 200, height: 200)
                    } else {
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .frame(width: 200, height: 200)
                    }
                }
                .padding()
                
                Button("Edit Crop") {
                    showingCropEditor = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button("Save Photo") {
                        let imageToSave = croppedImage ?? cropImageToSquare(originalImage)
                        onSave(imageToSave)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCropEditor) {
            ImageCropperView(image: originalImage) { cropped in
                croppedImage = cropped
            }
        }
        .onAppear {
            croppedImage = cropImageToSquare(originalImage)
        }
    }
    
    private func cropImageToSquare(_ image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let origin = CGPoint(x: (image.size.width - size) / 2, y: (image.size.height - size) / 2)
        let cropRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct ImageCropperView: UIViewControllerRepresentable {
    let image: UIImage
    let onCropped: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImageCropperView
        
        init(_ parent: ImageCropperView) {
            self.parent = parent
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onCropped(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onCropped(originalImage)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    PhotoEditorView(originalImage: UIImage(systemName: "person.fill") ?? UIImage()) { _ in }
}