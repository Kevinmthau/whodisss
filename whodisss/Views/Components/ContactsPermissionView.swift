import SwiftUI
import Contacts

struct ContactsPermissionView: View {
    let authorizationStatus: CNAuthorizationStatus
    let onGrantAccess: () -> Void
    let onOpenSettings: () -> Void

    private var permissionMessage: String {
        switch authorizationStatus {
        case .denied:
            "Contacts access is turned off for Whodisss. Open Settings to allow access."
        case .restricted:
            "Your device’s restrictions prevent Whodisss from accessing contacts. Check Screen Time or device management settings."
        default:
            "Whodisss needs access to your contacts to help you add profile photos."
        }
    }

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

            Text(permissionMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            if authorizationStatus == .denied {
                Button("Open Settings", action: onOpenSettings)
                    .buttonStyle(.borderedProminent)
            } else if authorizationStatus == .notDetermined {
                Button("Grant Access", action: onGrantAccess)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

#Preview("Request Access") {
    ContactsPermissionView(
        authorizationStatus: .notDetermined,
        onGrantAccess: {},
        onOpenSettings: {}
    )
}

#Preview("Access Denied") {
    ContactsPermissionView(
        authorizationStatus: .denied,
        onGrantAccess: {},
        onOpenSettings: {}
    )
}

#Preview("Access Restricted") {
    ContactsPermissionView(
        authorizationStatus: .restricted,
        onGrantAccess: {},
        onOpenSettings: {}
    )
}
