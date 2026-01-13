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
    static var preview: ContactInfo {
        ContactInfo(contact: CNContact(), hasImage: false)
    }
}