import Foundation
import SwiftUI

@MainActor
class PhotoEditorViewModel: ObservableObject, ErrorHandling {
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let originalImage: UIImage
    private let imageService: ImageServiceProtocol

    init(originalImage: UIImage, imageService: ImageServiceProtocol) {
        self.originalImage = originalImage
        self.imageService = imageService
    }

    func saveImage(
        onSave: @MainActor (UIImage) async -> Bool,
        failureMessage: @MainActor () -> String? = { nil }
    ) async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        defer { isSaving = false }
        clearError()

        guard let croppedImage = await cropImage() else {
            showErrorMessage("Failed to crop image. Please try again.")
            return false
        }

        guard await onSave(croppedImage) else {
            showErrorMessage(failureMessage() ?? "Failed to save contact image. Please try again.")
            return false
        }

        return true
    }

    func cropImage() async -> UIImage? {
        let scale = self.scale
        let offset = self.offset
        let originalImage = self.originalImage
        let imageService = self.imageService

        return await Task.detached {
            imageService.cropImageWithTransform(
                originalImage,
                scale: scale,
                offset: offset
            )
        }.value
    }
}
