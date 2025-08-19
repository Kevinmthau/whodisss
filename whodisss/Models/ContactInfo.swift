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
}

extension ContactInfo {
    static var preview: ContactInfo {
        ContactInfo(contact: CNContact(), hasImage: false)
    }
}