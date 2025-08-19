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

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ContactsPermissionView: View {
    let onGrantAccess: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Contacts Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Whodiss needs access to your contacts to help you add profile photos.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Grant Access", action: onGrantAccess)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        ContactsListView()
    }
}