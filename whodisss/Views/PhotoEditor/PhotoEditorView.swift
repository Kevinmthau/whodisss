import SwiftUI
import UIKit

struct PhotoEditorView: View {
    let originalImage: UIImage
    let onSave: @MainActor (UIImage) async -> Bool
    let saveErrorMessage: @MainActor () -> String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PhotoEditorViewModel

    init(
        originalImage: UIImage,
        imageService: ImageServiceProtocol = ImageService(),
        saveErrorMessage: @escaping @MainActor () -> String? = { nil },
        onSave: @escaping @MainActor (UIImage) async -> Bool
    ) {
        self.originalImage = originalImage
        self.onSave = onSave
        self.saveErrorMessage = saveErrorMessage
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
                .allowsHitTesting(!viewModel.isSaving)

                Spacer()

                PhotoEditorActions(
                    isSaving: viewModel.isSaving,
                    onCancel: { dismiss() },
                    onSave: saveCroppedImage
                )
            }
            .padding()
            .navigationBarHidden(true)
            .disabled(viewModel.isSaving)
        }
        .interactiveDismissDisabled(viewModel.isSaving)
        .errorAlert(for: viewModel)
    }

    private func saveCroppedImage() {
        Task {
            if await viewModel.saveImage(onSave: onSave, failureMessage: saveErrorMessage) {
                dismiss()
            }
        }
    }
}

#Preview {
    PhotoEditorView(originalImage: UIImage(systemName: "person.fill") ?? UIImage()) { _ in true }
}
