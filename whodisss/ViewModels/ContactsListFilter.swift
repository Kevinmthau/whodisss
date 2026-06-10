import SwiftUI

enum ContactsListFilterMode: Equatable {
    case missingPhotos
    case allContacts

    var navigationTitle: String {
        switch self {
        case .missingPhotos:
            "Missing Photos"
        case .allContacts:
            "Contacts"
        }
    }

    var emptyState: ContactsListEmptyState {
        switch self {
        case .missingPhotos:
            ContactsListEmptyState(
                icon: "checkmark.circle",
                title: "All contacts have photos!",
                message: "Great job! All your contacts now have profile photos.",
                iconColor: .green
            )
        case .allContacts:
            ContactsListEmptyState(
                icon: "person.crop.circle",
                title: "No contacts found",
                message: nil,
                iconColor: .gray
            )
        }
    }
}

struct ContactsListEmptyState {
    let icon: String
    let title: String
    let message: String?
    let iconColor: Color
}

struct ContactsListFilter: Equatable {
    var mode: ContactsListFilterMode = .missingPhotos
    var searchText = ""

    func displayedContacts(
        allContacts: [ContactInfo],
        contactsWithoutImages: [ContactInfo]
    ) -> [ContactInfo] {
        let baseContacts = switch mode {
        case .missingPhotos:
            contactsWithoutImages
        case .allContacts:
            allContacts
        }

        guard !searchText.isEmpty else {
            return baseContacts
        }

        return baseContacts.filter { contact in
            contact.displayName.localizedCaseInsensitiveContains(searchText)
                || contact.companyName?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}
