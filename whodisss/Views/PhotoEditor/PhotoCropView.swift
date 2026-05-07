import SwiftUI
import UIKit

struct PhotoCropView: View {
    let image: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    @State private var lastScale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    private var combinedOffset: CGSize {
        CropConfiguration.clampedOffset(
            CGSize(
                width: offset.width + dragOffset.width,
                height: offset.height + dragOffset.height
            ),
            for: image.size,
            scale: scale
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
            .gesture(SimultaneousGesture(magnificationGesture, dragGesture))
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                let newScale = CropConfiguration.clampedScale(scale * delta)
                scale = newScale
                offset = CropConfiguration.clampedOffset(offset, for: image.size, scale: newScale)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let proposed = CGSize(
                    width: offset.width + value.translation.width,
                    height: offset.height + value.translation.height
                )
                offset = CropConfiguration.clampedOffset(proposed, for: image.size, scale: scale)
            }
    }
}
