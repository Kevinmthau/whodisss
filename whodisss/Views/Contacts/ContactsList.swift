import SwiftUI

struct ContactsList: View {
    let contacts: [ContactInfo]
    let viewModel: ContactsViewModel

    var body: some View {
        List(contacts) { contactInfo in
            NavigationLink(destination: ContactDetailView(contactInfo: contactInfo, viewModel: viewModel)) {
                ContactRowView(contactInfo: contactInfo)
            }
        }
        .listStyle(PlainListStyle())
        .edgesIgnoringSafeArea(.horizontal)
        .scrollDismissesKeyboard(.immediately)
        .refreshable {
            await viewModel.refreshContacts()
        }
    }
}

#Preview {
    NavigationView {
        ContactsList(
            contacts: [.preview],
            viewModel: ContactsViewModel()
        )
    }
}
