import Foundation
import Contacts
import UIKit

struct ContactInfo: Identifiable {
    let id = UUID()
    let contact: CNContact
    let hasImage: Bool
    
    var displayName: String {
        if !contact.givenName.isEmpty && !contact.familyName.isEmpty {
            return "\(contact.givenName) \(contact.familyName)"
        } else if !contact.givenName.isEmpty {
            return contact.givenName
        } else if !contact.familyName.isEmpty {
            return contact.familyName
        } else {
            return contact.organizationName.isEmpty ? "Unknown Contact" : contact.organizationName
        }
    }
    
    var profileImage: UIImage? {
        guard let imageData = contact.imageData else { return nil }
        return UIImage(data: imageData)
    }
}

@MainActor
class ContactDataManager: ObservableObject {
    @Published var contacts: [ContactInfo] = []
    @Published var contactsWithoutImages: [ContactInfo] = []
    @Published var isLoading = false
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    private let contactStore = CNContactStore()
    
    init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func requestContactsAccess() async {
        isLoading = true
        
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            
            if granted {
                await loadContacts()
            }
        } catch {
            print("Error requesting contacts access: \(error)")
        }
        
        isLoading = false
    }
    
    func loadContacts() async {
        guard authorizationStatus == .authorized else { return }
        
        isLoading = true
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactOrganizationNameKey,
            CNContactImageDataKey,
            CNContactImageDataAvailableKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        let store = contactStore
        
        // Move heavy work to background thread
        let result = await Task.detached {
            do {
                var allContacts: [ContactInfo] = []
                var contactsWithoutImages: [ContactInfo] = []
                
                try store.enumerateContacts(with: request) { contact, _ in
                    let hasImage = contact.imageDataAvailable && contact.imageData != nil
                    let contactInfo = ContactInfo(contact: contact, hasImage: hasImage)
                    
                    allContacts.append(contactInfo)
                    
                    if !hasImage {
                        contactsWithoutImages.append(contactInfo)
                    }
                }
                
                let sortedContacts = allContacts.sorted { $0.displayName < $1.displayName }
                let sortedContactsWithoutImages = contactsWithoutImages.sorted { $0.displayName < $1.displayName }
                
                return (sortedContacts, sortedContactsWithoutImages, nil as Error?)
                
            } catch {
                return ([], [], error)
            }
        }.value
        
        // Update UI on main thread
        self.contacts = result.0
        self.contactsWithoutImages = result.1
        
        if let error = result.2 {
            print("Error fetching contacts: \(error)")
        }
        
        isLoading = false
    }
    
    func saveImageToContact(_ contact: CNContact, image: UIImage) async -> Bool {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return false }
        
        let mutableContact = contact.mutableCopy() as! CNMutableContact
        mutableContact.imageData = imageData
        
        let request = CNSaveRequest()
        request.update(mutableContact)
        
        do {
            try contactStore.execute(request)
            await loadContacts()
            return true
        } catch {
            print("Error saving contact image: \(error)")
            return false
        }
    }
}