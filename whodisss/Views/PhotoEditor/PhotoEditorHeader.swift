import SwiftUI

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
