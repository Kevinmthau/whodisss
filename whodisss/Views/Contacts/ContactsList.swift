import SwiftUI

struct ContactsList: View {
    let contacts: [ContactInfo]
    let viewModel: ContactsViewModel
    @Binding var scrollPositionID: String?

    var body: some View {
        List(contacts) { contactInfo in
            NavigationLink {
                NativeContactDetailView(
                    contactInfo: contactInfo,
                    viewModel: viewModel,
                    automaticallySearchImages: viewModel.listFilter.mode == .missingPhotos
                )
            } label: {
                ContactRowView(contactInfo: contactInfo)
            }
        }
        .listStyle(PlainListStyle())
        .edgesIgnoringSafeArea(.horizontal)
        .scrollDismissesKeyboard(.immediately)
        .scrollPosition(id: $scrollPositionID)
        .contentMargins(.bottom, 96, for: .scrollContent)
        .refreshable {
            await viewModel.refreshContacts()
        }
    }
}

#Preview {
    NavigationStack {
        ContactsList(
            contacts: [.preview],
            viewModel: ContactsViewModel(),
            scrollPositionID: .constant(nil)
        )
    }
}
