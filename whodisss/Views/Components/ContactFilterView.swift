import SwiftUI

struct ContactFilterView: View {
    @Binding var showOnlyMissingPhotos: Bool
    let missingCount: Int
    let totalCount: Int

    var body: some View {
        Picker("Contact Filter", selection: $showOnlyMissingPhotos) {
            Text("Missing Photos (\(missingCount))").tag(true)
            Text("All Contacts (\(totalCount))").tag(false)
        }
        .pickerStyle(.segmented)
        .padding()
    }
}

#Preview {
    ContactFilterView(
        showOnlyMissingPhotos: .constant(true),
        missingCount: 10,
        totalCount: 50
    )
}
