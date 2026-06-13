import SwiftUI

enum CropConfiguration {
    static let maxScale: CGFloat = 5.0
    static let frameSize: CGFloat = 280
    static let cropSize: CGFloat = 240

    /// Fallback minimum scale used when the image size is unknown.
    static let defaultMinScale: CGFloat = 1.0

    /// Smallest scale that still lets the *entire* image fit inside the circular crop.
    ///
    /// At scale `1.0` the image fills the crop circle (scaledToFill), so non-square
    /// images always overflow the circle and can't be shrunk to fit. Allowing the
    /// scale to drop below `1.0` lets users zoom out until the whole image fits within
    /// the profile circle. The lower bound shrinks the image until its bounding box's
    /// diagonal equals the circle's diameter, so nothing is clipped by the circular mask.
    static func minScale(for imageSize: CGSize) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0 else { return defaultMinScale }

        let aspectRatio = imageSize.width / imageSize.height

        // Rendered size at scale 1.0 (scaledToFill: the shorter side matches the crop).
        let baseWidth = aspectRatio > 1 ? cropSize * aspectRatio : cropSize
        let baseHeight = aspectRatio > 1 ? cropSize : cropSize / aspectRatio

        let diagonal = (baseWidth * baseWidth + baseHeight * baseHeight).squareRoot()
        guard diagonal > 0 else { return defaultMinScale }

        let fitScale = cropSize / diagonal
        return min(fitScale, defaultMinScale)
    }

    static func clampedScale(_ scale: CGFloat, for imageSize: CGSize) -> CGFloat {
        min(max(scale, minScale(for: imageSize)), maxScale)
    }

    static func renderedImageSize(for imageSize: CGSize, scale: CGFloat) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: cropSize, height: cropSize)
        }

        let aspectRatio = imageSize.width / imageSize.height
        let boundedScale = clampedScale(scale, for: imageSize)

        if aspectRatio > 1 {
            return CGSize(
                width: cropSize * boundedScale * aspectRatio,
                height: cropSize * boundedScale
            )
        }

        return CGSize(
            width: cropSize * boundedScale,
            height: cropSize * boundedScale / aspectRatio
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
