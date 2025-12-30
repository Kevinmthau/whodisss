import Foundation
import SwiftUI

@MainActor
class PhotoEditorViewModel: ObservableObject, ErrorHandling {
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var errorMessage: String?
    @Published var showError = false

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
            imageService.cropImageWithTransform(
                originalImage,
                scale: scale,
                offset: offset
            )
        }.value
    }
}
