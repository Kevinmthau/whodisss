import SwiftUI
import UIKit

struct PhotoEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PhotoEditorViewModel

    init(
        originalImage: UIImage,
        imageService: ImageServiceProtocol = ImageService(),
        onSave: @escaping (UIImage) -> Void
    ) {
        self.originalImage = originalImage
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(
            originalImage: originalImage,
            imageService: imageService
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
                    onSave: saveCroppedImage
                )
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    private func saveCroppedImage() {
        Task {
            if let croppedImage = await viewModel.cropImage() {
                onSave(croppedImage)
                dismiss()
            }
        }
    }
}

#Preview {
    PhotoEditorView(originalImage: UIImage(systemName: "person.fill") ?? UIImage()) { _ in }
}
