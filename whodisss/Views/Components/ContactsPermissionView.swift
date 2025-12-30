import SwiftUI

struct ContactsPermissionView: View {
    let onGrantAccess: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Contacts Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Whodiss needs access to your contacts to help you add profile photos.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Grant Access", action: onGrantAccess)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContactsPermissionView {
        print("Grant access tapped")
    }
}
