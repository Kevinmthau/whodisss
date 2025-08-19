import Foundation
import UIKit

protocol ImageServiceProtocol {
    func downloadImage(from url: URL) async throws -> UIImage
    func cropImageToSquare(_ image: UIImage) -> UIImage
    func cropImageToSquare(_ image: UIImage, scale: CGFloat, offset: CGSize) -> UIImage
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
    
    func cropImageToSquare(_ image: UIImage, scale: CGFloat, offset: CGSize) -> UIImage {
        let cropSize: CGFloat = 240
        let outputSize = CGSize(width: cropSize, height: cropSize)
        
        UIGraphicsBeginImageContextWithOptions(outputSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        context.translateBy(x: outputSize.width / 2, y: outputSize.height / 2)
        
        context.translateBy(x: offset.width, y: offset.height)
        
        context.scaleBy(x: scale, y: scale)
        
        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height
        
        var drawWidth: CGFloat
        var drawHeight: CGFloat
        
        if aspectRatio > 1 {
            drawHeight = cropSize
            drawWidth = cropSize * aspectRatio
        } else {
            drawWidth = cropSize
            drawHeight = cropSize / aspectRatio
        }
        
        let drawRect = CGRect(
            x: -drawWidth / 2,
            y: -drawHeight / 2,
            width: drawWidth,
            height: drawHeight
        )
        
        image.draw(in: drawRect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
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