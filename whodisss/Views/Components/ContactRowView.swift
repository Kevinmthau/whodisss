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
    ContactRowView(contactInfo: .preview)
        .padding()
}