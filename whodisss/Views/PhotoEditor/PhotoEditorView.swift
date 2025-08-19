import SwiftUI
import UIKit

struct PhotoEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PhotoEditorViewModel
    
    init(originalImage: UIImage, onSave: @escaping (UIImage) -> Void) {
        self.originalImage = originalImage
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(
            originalImage: originalImage,
            imageService: ImageService()
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                PhotoEditorHeader()
                
                PhotoPreview(image: viewModel.croppedImage ?? originalImage)
                    .padding()
                
                Spacer()
                
                PhotoEditorActions(
                    onCancel: { dismiss() },
                    onSave: {
                        let imageToSave = viewModel.croppedImage ?? originalImage
                        onSave(imageToSave)
                        dismiss()
                    }
                )
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.cropImage()
        }
    }
}

struct PhotoEditorHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Crop Photo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Adjust the image to fit as a contact profile photo")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct PhotoPreview: View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .frame(width: 200, height: 200)
        }
    }
}

struct PhotoEditorActions: View {
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            
            Button("Save Photo", action: onSave)
                .buttonStyle(.borderedProminent)
        }
    }
}

@MainActor
class PhotoEditorViewModel: ObservableObject {
    @Published var croppedImage: UIImage?
    
    private let originalImage: UIImage
    private let imageService: ImageServiceProtocol
    
    init(originalImage: UIImage, imageService: ImageServiceProtocol) {
        self.originalImage = originalImage
        self.imageService = imageService
    }
    
    func cropImage() {
        croppedImage = imageService.cropImageToSquare(originalImage)
    }
}

#Preview {
    PhotoEditorView(originalImage: UIImage(systemName: "person.fill") ?? UIImage()) { _ in }
}