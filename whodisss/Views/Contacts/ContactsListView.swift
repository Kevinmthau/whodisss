import SwiftUI
import Contacts

struct ContactsListView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var showOnlyMissingPhotos = true
    @State private var searchText = ""

    var displayedContacts: [ContactInfo] {
        let baseContacts = showOnlyMissingPhotos ? viewModel.contactsWithoutImages : viewModel.contacts

        if searchText.isEmpty {
            return baseContacts
        } else {
            return baseContacts.filter { contact in
                contact.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack {
            if viewModel.authorizationStatus != .authorized {
                ContactsPermissionView {
                    Task {
                        await viewModel.requestContactsAccess()
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ContactFilterView(
                        showOnlyMissingPhotos: $showOnlyMissingPhotos,
                        missingCount: viewModel.contactsWithoutImages.count,
                        totalCount: viewModel.contacts.count
                    )

                    SearchBarView(searchText: $searchText)
                        .padding(.horizontal)
                        .padding(.bottom)

                    if viewModel.isLoading {
                        LoadingView("Loading contacts...")
                    } else if displayedContacts.isEmpty {
                        EmptyStateView(
                            icon: showOnlyMissingPhotos ? "checkmark.circle" : "person.crop.circle",
                            title: showOnlyMissingPhotos ? "All contacts have photos!" : "No contacts found",
                            message: showOnlyMissingPhotos ? "Great job! All your contacts now have profile photos." : nil,
                            iconColor: showOnlyMissingPhotos ? .green : .gray
                        )
                    } else {
                        ContactsList(
                            contacts: displayedContacts,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
        .task {
            if viewModel.authorizationStatus == .authorized {
                await viewModel.loadContacts()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    NavigationView {
        ContactsListView()
    }
}
