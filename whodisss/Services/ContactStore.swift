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
        CNContactImageDataAvailableKey
    ] as [CNKeyDescriptor]
    
    func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }
    
    func fetchContacts() async throws -> [CNContact] {
        let request = CNContactFetchRequest(keysToFetch: Self.keysToFetch)
        
        return try await withCheckedThrowingContinuation { continuation in
            var contacts: [CNContact] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    contacts.append(contact)
                }
                continuation.resume(returning: contacts)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateContact(_ contact: CNMutableContact) throws {
        let request = CNSaveRequest()
        request.update(contact)
        try store.execute(request)
    }
}