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
                .frame(width: CropConfiguration.frameSize, height: CropConfiguration.frameSize)

            ZStack {
                Color.black.opacity(0.3)
                    .frame(width: CropConfiguration.frameSize, height: CropConfiguration.frameSize)

                Circle()
                    .fill(Color.white)
                    .frame(width: CropConfiguration.cropSize, height: CropConfiguration.cropSize)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: CropConfiguration.cropSize * scale, height: CropConfiguration.cropSize * scale)
                    .offset(combinedOffset)
                    .frame(width: CropConfiguration.cropSize, height: CropConfiguration.cropSize)
                    .mask(
                        Circle()
                            .frame(width: CropConfiguration.cropSize, height: CropConfiguration.cropSize)
                    )

                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: CropConfiguration.cropSize, height: CropConfiguration.cropSize)
            }
            .frame(width: CropConfiguration.frameSize, height: CropConfiguration.frameSize)
            .clipped()
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            let newScale = scale * delta
                            scale = min(max(newScale, CropConfiguration.minScale), CropConfiguration.maxScale)
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

#Preview {
    PhotoEditorView(originalImage: UIImage(systemName: "person.fill") ?? UIImage()) { _ in }
}
