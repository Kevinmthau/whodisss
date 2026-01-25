import SwiftUI

struct ContactsList: View {
    let contacts: [ContactInfo]
    let viewModel: ContactsViewModel

    var body: some View {
        List(contacts) { contactInfo in
            NavigationLink(destination: NativeContactDetailView(contactInfo: contactInfo, viewModel: viewModel)) {
                ContactRowView(contactInfo: contactInfo)
            }
        }
        .listStyle(PlainListStyle())
        .edgesIgnoringSafeArea(.horizontal)
        .scrollDismissesKeyboard(.immediately)
        .contentMargins(.bottom, 60, for: .scrollContent)
        .refreshable {
            await viewModel.refreshContacts()
        }
    }
}

#Preview {
    NavigationStack {
        ContactsList(
            contacts: [.preview],
            viewModel: ContactsViewModel()
        )
    }
}
