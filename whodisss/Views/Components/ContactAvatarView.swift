import SwiftUI

struct ContactAvatarView: View {
    let contactInfo: ContactInfo
    let size: CGFloat

    var body: some View {
        Group {
            if let image = contactInfo.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))

                    Text(contactInfo.initials)
                        .font(.system(size: size * 0.4, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    ContactAvatarView(contactInfo: .preview, size: 80)
}
