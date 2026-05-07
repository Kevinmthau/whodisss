import SwiftUI

struct ContactsListView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var showingFilterOptions = false

    private var shouldHideNavigationBar: Bool {
        !viewModel.hasContactsAccess
    }

    private var shouldShowSearchBar: Bool {
        viewModel.hasContactsAccess
    }

    var body: some View {
        VStack {
            if !viewModel.hasContactsAccess {
                ContactsPermissionView(onGrantAccess: requestContactsAccess)
            } else {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        LoadingView("Loading contacts...")
                    } else if viewModel.displayedContacts.isEmpty {
                        let emptyState = viewModel.listEmptyState
                        EmptyStateView(
                            icon: emptyState.icon,
                            title: emptyState.title,
                            message: emptyState.message,
                            iconColor: emptyState.iconColor
                        )
                    } else {
                        ContactsList(
                            contacts: viewModel.displayedContacts,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
        .navigationTitle(viewModel.listNavigationTitle)
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
                        SearchBarView(searchText: $viewModel.listFilter.searchText)
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
                viewModel.showMissingPhotoContacts()
            }

            Button("All Contacts (\(viewModel.contacts.count))") {
                viewModel.showAllContacts()
            }

            Button("Cancel", role: .cancel) { }
        }
        .task {
            await loadContactsIfNeeded()
        }
        .errorAlert(for: viewModel)
    }

    private func requestContactsAccess() {
        Task {
            await viewModel.requestContactsAccess()
        }
    }

    private func loadContactsIfNeeded() async {
        guard viewModel.hasContactsAccess else { return }

        await viewModel.loadContacts()
    }
}

#Preview {
    NavigationStack {
        ContactsListView()
    }
}
