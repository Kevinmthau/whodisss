import SwiftUI

enum CropConfiguration {
    static let minScale: CGFloat = 1.0
    static let maxScale: CGFloat = 5.0
    static let frameSize: CGFloat = 280
    static let cropSize: CGFloat = 240

    static func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, minScale), maxScale)
    }

    static func renderedImageSize(for imageSize: CGSize, scale: CGFloat) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: cropSize, height: cropSize)
        }

        let aspectRatio = imageSize.width / imageSize.height
        let clampedScale = clampedScale(scale)

        if aspectRatio > 1 {
            return CGSize(
                width: cropSize * clampedScale * aspectRatio,
                height: cropSize * clampedScale
            )
        }

        return CGSize(
            width: cropSize * clampedScale,
            height: cropSize * clampedScale / aspectRatio
        )
    }

    static func clampedOffset(_ offset: CGSize, for imageSize: CGSize, scale: CGFloat) -> CGSize {
        let renderedSize = renderedImageSize(for: imageSize, scale: scale)
        let maxX = max((renderedSize.width - cropSize) / 2, 0)
        let maxY = max((renderedSize.height - cropSize) / 2, 0)

        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}
