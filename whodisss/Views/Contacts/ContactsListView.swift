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
        .navigationTitle(showOnlyMissingPhotos ? "Missing Photos" : "Contacts")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Menu {
                    Button {
                        showOnlyMissingPhotos = true
                    } label: {
                        HStack {
                            Text("Missing Photos (\(viewModel.contactsWithoutImages.count))")
                            if showOnlyMissingPhotos {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Button {
                        showOnlyMissingPhotos = false
                    } label: {
                        HStack {
                            Text("All Contacts (\(viewModel.contacts.count))")
                            if !showOnlyMissingPhotos {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .glassEffect(.regular)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }

                SearchBarView(searchText: $searchText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
    NavigationStack {
        ContactsListView()
    }
}
