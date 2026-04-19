import Foundation
import Contacts
import UIKit

struct ContactInfo: Identifiable {
    var id: String { contact.identifier }
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
    
    var initials: String {
        let components = displayName.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? "?" : initials
    }

    var locationString: String? {
        guard let address = contact.postalAddresses.first?.value else { return nil }
        let city = address.city
        let state = address.state
        if !city.isEmpty && !state.isEmpty {
            return "\(city), \(state)"
        } else if !city.isEmpty {
            return city
        } else if !state.isEmpty {
            return state
        }
        return nil
    }
}

extension ContactInfo {
    static func hasImage(for contact: CNContact) -> Bool {
        let hasImageDataAvailable = contact.isKeyAvailable(CNContactImageDataAvailableKey) && contact.imageDataAvailable
        let hasImageData = contact.isKeyAvailable(CNContactImageDataKey) && contact.imageData != nil
        return hasImageDataAvailable || hasImageData
    }

    static var preview: ContactInfo {
        ContactInfo(contact: CNContact(), hasImage: false)
    }
}

extension Array where Element == ContactInfo {
    func sortedByDisplayName() -> [ContactInfo] {
        sorted { $0.displayName < $1.displayName }
    }

    mutating func sortByDisplayName() {
        sort { $0.displayName < $1.displayName }
    }

    mutating func upsertByID(_ contact: ContactInfo) {
        if let index = firstIndex(where: { $0.id == contact.id }) {
            self[index] = contact
        } else {
            append(contact)
        }
    }
}
