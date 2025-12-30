import SwiftUI

struct ContactRowView: View {
    let contactInfo: ContactInfo

    var body: some View {
        HStack(spacing: 12) {
            ContactAvatarView(contactInfo: contactInfo, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(contactInfo.displayName)
                    .font(.headline)
                    .lineLimit(1)
            }

            Spacer()

            if !contactInfo.hasImage {
                Image(systemName: "camera.badge.ellipsis")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactRowView(contactInfo: .preview)
        .padding()
}
