import SwiftUI
import Contacts

struct ContactsListView: View {
    @StateObject private var contactDataManager = ContactDataManager()
    @State private var showOnlyMissingPhotos = true
    
    var displayedContacts: [ContactInfo] {
        showOnlyMissingPhotos ? contactDataManager.contactsWithoutImages : contactDataManager.contacts
    }
    
    var body: some View {
        VStack {
            if contactDataManager.authorizationStatus != .authorized {
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
                    
                    Button("Grant Access") {
                        Task {
                            await contactDataManager.requestContactsAccess()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack {
                    Picker("Contact Filter", selection: $showOnlyMissingPhotos) {
                        Text("Missing Photos (\(contactDataManager.contactsWithoutImages.count))").tag(true)
                        Text("All Contacts (\(contactDataManager.contacts.count))").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if contactDataManager.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading contacts...")
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if displayedContacts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: showOnlyMissingPhotos ? "checkmark.circle" : "person.crop.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text(showOnlyMissingPhotos ? "All contacts have photos!" : "No contacts found")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if showOnlyMissingPhotos {
                                Text("Great job! All your contacts now have profile photos.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(displayedContacts) { contactInfo in
                            NavigationLink(destination: ContactDetailView(contactInfo: contactInfo, dataManager: contactDataManager)) {
                                ContactRowView(contactInfo: contactInfo)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .edgesIgnoringSafeArea(.horizontal)
                    }
                }
            }
        }
        .task {
            if contactDataManager.authorizationStatus == .authorized {
                await contactDataManager.loadContacts()
            }
        }
    }
}

struct ContactRowView: View {
    let contactInfo: ContactInfo
    
    var body: some View {
        HStack {
            Group {
                if let image = contactInfo.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contactInfo.displayName)
                    .font(.headline)
            }
            
            Spacer()
            
            if !contactInfo.hasImage {
                Image(systemName: "camera.badge.ellipsis")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        ContactsListView()
    }
}