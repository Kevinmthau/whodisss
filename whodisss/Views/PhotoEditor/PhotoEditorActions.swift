import SwiftUI

struct PhotoEditorActions: View {
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .foregroundColor(.red)

            Button(isSaving ? "Saving..." : "Save Photo", action: onSave)
                .buttonStyle(.borderedProminent)
        }
    }
}
