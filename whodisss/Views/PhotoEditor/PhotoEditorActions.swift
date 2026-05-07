import SwiftUI

struct PhotoEditorActions: View {
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .foregroundColor(.red)

            Button("Save Photo", action: onSave)
                .buttonStyle(.borderedProminent)
        }
    }
}
