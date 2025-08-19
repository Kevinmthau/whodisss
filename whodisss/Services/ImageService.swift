import Foundation
import UIKit

protocol ImageServiceProtocol {
    func downloadImage(from url: URL) async throws -> UIImage
    func cropImageToSquare(_ image: UIImage) -> UIImage
    func compressImage(_ image: UIImage, quality: CGFloat) -> Data?
}

class ImageService: ImageServiceProtocol {
    func downloadImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageServiceError.invalidImageData
        }
        return image
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2
        )
        let cropRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}

enum ImageServiceError: LocalizedError {
    case invalidImageData
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Failed to create image from data"
        case .compressionFailed:
            return "Failed to compress image"
        }
    }
}