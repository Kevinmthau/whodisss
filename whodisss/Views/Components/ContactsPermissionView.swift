import SwiftUI

struct ContactsPermissionView: View {
    let onGrantAccess: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 14) {
                Image("WelcomeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.14), radius: 16, x: 0, y: 10)

                Text("Whodisss")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                Text("Contact photo finder")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Text("Whodiss needs access to your contacts to help you add profile photos.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            Button("Grant Access", action: onGrantAccess)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview {
    ContactsPermissionView {
        print("Grant access tapped")
    }
}
