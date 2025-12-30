import SwiftUI

struct ContactHeaderView: View {
    let contactInfo: ContactInfo

    var body: some View {
        VStack(spacing: 20) {
            ContactAvatarView(contactInfo: contactInfo, size: 120)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )

            VStack(spacing: 4) {
                Text(contactInfo.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if !contactInfo.contact.organizationName.isEmpty {
                    Text(contactInfo.contact.organizationName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContactHeaderView(contactInfo: .preview)
}
