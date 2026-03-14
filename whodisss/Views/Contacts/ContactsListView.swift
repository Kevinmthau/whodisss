import SwiftUI
import Contacts

struct ContactsListView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var showOnlyMissingPhotos = true
    @State private var searchText = ""
    @State private var showingFilterOptions = false

    private var shouldHideNavigationBar: Bool {
        !viewModel.hasContactsAccess
    }

    private var shouldShowSearchBar: Bool {
        viewModel.hasContactsAccess
    }

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
            if !viewModel.hasContactsAccess {
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
        .toolbar(shouldHideNavigationBar ? .hidden : .visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if viewModel.hasContactsAccess {
                HStack(spacing: 12) {
                    Button {
                        showingFilterOptions = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .glassEffect(.regular)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }

                    if shouldShowSearchBar {
                        SearchBarView(searchText: $searchText)
                            .frame(maxWidth: .infinity)
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .confirmationDialog("Show Contacts", isPresented: $showingFilterOptions, titleVisibility: .visible) {
            Button("Missing Photos (\(viewModel.contactsWithoutImages.count))") {
                showOnlyMissingPhotos = true
            }

            Button("All Contacts (\(viewModel.contacts.count))") {
                showOnlyMissingPhotos = false
            }

            Button("Cancel", role: .cancel) { }
        }
        .task {
            if viewModel.hasContactsAccess {
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
