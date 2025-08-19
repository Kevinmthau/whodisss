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
                
                PhotoCropView(
                    image: originalImage,
                    scale: $viewModel.scale,
                    offset: $viewModel.offset
                )
                .padding()
                
                Spacer()
                
                PhotoEditorActions(
                    onCancel: { dismiss() },
                    onSave: {
                        Task {
                            if let croppedImage = await viewModel.cropImage() {
                                onSave(croppedImage)
                                dismiss()
                            }
                        }
                    }
                )
            }
            .padding()
            .navigationBarHidden(true)
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

struct PhotoCropView: View {
    let image: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    private let frameSize: CGFloat = 280
    private let cropSize: CGFloat = 240
    
    var combinedOffset: CGSize {
        CGSize(
            width: offset.width + dragOffset.width,
            height: offset.height + dragOffset.height
        )
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: frameSize, height: frameSize)
            
            ZStack {
                Color.black.opacity(0.3)
                    .frame(width: frameSize, height: frameSize)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: cropSize, height: cropSize)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cropSize * scale, height: cropSize * scale)
                    .scaleEffect(1.0)
                    .offset(combinedOffset)
                    .frame(width: cropSize, height: cropSize)
                    .mask(
                        Circle()
                            .frame(width: cropSize, height: cropSize)
                    )
                
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
            }
            .frame(width: frameSize, height: frameSize)
            .clipped()
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            let newScale = scale * delta
                            scale = min(max(newScale, minScale), maxScale)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        },
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                        }
                )
            )
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
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    
    private let originalImage: UIImage
    private let imageService: ImageServiceProtocol
    
    init(originalImage: UIImage, imageService: ImageServiceProtocol) {
        self.originalImage = originalImage
        self.imageService = imageService
    }
    
    func cropImage() async -> UIImage? {
        let scale = self.scale
        let offset = self.offset
        let originalImage = self.originalImage
        let imageService = self.imageService
        
        return await Task.detached {
            imageService.cropImageToSquare(
                originalImage,
                scale: scale,
                offset: offset
            )
        }.value
    }
}

#Preview {
    PhotoEditorView(originalImage: UIImage(systemName: "person.fill") ?? UIImage()) { _ in }
}