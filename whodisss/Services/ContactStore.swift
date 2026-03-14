import Foundation
import Contacts

protocol ContactStoreProtocol {
    func requestAccess() async throws -> Bool
    func fetchContacts() async throws -> [CNContact]
    func updateContact(_ contact: CNMutableContact) throws
    var authorizationStatus: CNAuthorizationStatus { get }
}

class ContactStore: ContactStoreProtocol {
    private let store = CNContactStore()
    
    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }
    
    static let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey,
        CNContactFamilyNameKey,
        CNContactOrganizationNameKey,
        CNContactImageDataKey,
        CNContactImageDataAvailableKey,
        CNContactPostalAddressesKey
    ] as [CNKeyDescriptor]
    
    func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }
    
    func fetchContacts() async throws -> [CNContact] {
        let request = CNContactFetchRequest(keysToFetch: Self.keysToFetch)

        var contacts: [CNContact] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
            return contacts
        } catch {
            throw error
        }
    }
    
    func updateContact(_ contact: CNMutableContact) throws {
        let request = CNSaveRequest()
        request.update(contact)
        try store.execute(request)
    }
}
