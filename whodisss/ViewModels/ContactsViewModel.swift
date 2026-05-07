import Foundation
import SwiftUI
import Contacts

@MainActor
class ContactsViewModel: ObservableObject, ErrorHandling {
    @Published var contacts: [ContactInfo] = []
    @Published var contactsWithoutImages: [ContactInfo] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var listFilter = ContactsListFilter()

    private let contactStore: ContactStoreProtocol
    private let imageService: ImageServiceProtocol

    init(
        contactStore: ContactStoreProtocol = ContactStore(),
        imageService: ImageServiceProtocol = ImageService()
    ) {
        self.contactStore = contactStore
        self.imageService = imageService
        self.authorizationStatus = contactStore.authorizationStatus
    }

    var hasContactsAccess: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    var displayedContacts: [ContactInfo] {
        listFilter.displayedContacts(
            allContacts: contacts,
            contactsWithoutImages: contactsWithoutImages
        )
    }

    var listNavigationTitle: String {
        listFilter.mode.navigationTitle
    }

    var listEmptyState: ContactsListEmptyState {
        listFilter.mode.emptyState
    }

    func showMissingPhotoContacts() {
        listFilter.mode = .missingPhotos
    }

    func showAllContacts() {
        listFilter.mode = .allContacts
    }

    func requestContactsAccess() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let granted = try await contactStore.requestAccess()
            authorizationStatus = contactStore.authorizationStatus

            if granted {
                await loadContacts()
            }
        } catch {
            handleError(error, message: "Failed to request contacts access")
        }
    }

    func loadContacts() async {
        guard hasContactsAccess else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedContacts = try await fetchContactsInBackground()
            processContacts(fetchedContacts)
        } catch {
            handleError(error, message: "Failed to load contacts")
        }
    }

    private func fetchContactsInBackground() async throws -> [CNContact] {
        try await Task.detached(priority: .userInitiated) {
            try await self.contactStore.fetchContacts()
        }.value
    }

    private func processContacts(_ fetchedContacts: [CNContact]) {
        let allContacts = fetchedContacts.map {
            ContactInfo(contact: $0, hasImage: ContactInfo.hasImage(for: $0))
        }

        contacts = allContacts.sortedByDisplayName()
        contactsWithoutImages = allContacts.filter { !$0.hasImage }.sortedByDisplayName()
    }

    private func updateCachedContact(_ contact: CNContact) {
        let updated = ContactInfo(contact: contact, hasImage: ContactInfo.hasImage(for: contact))

        contacts.upsertByID(updated)
        contacts.sortByDisplayName()

        if updated.hasImage {
            contactsWithoutImages.removeAll { $0.id == updated.id }
        } else {
            contactsWithoutImages.upsertByID(updated)
            contactsWithoutImages.sortByDisplayName()
        }
    }

    func saveImageToContact(_ contact: CNContact, image: UIImage) async -> Bool {
        guard let imageData = imageService.compressImage(image, quality: 0.8) else {
            handleError(nil, message: "Failed to compress image")
            return false
        }

        guard let mutableContact = contact.mutableCopy() as? CNMutableContact else {
            handleError(nil, message: "Failed to create mutable contact")
            return false
        }

        mutableContact.imageData = imageData

        do {
            try contactStore.updateContact(mutableContact)

            if let updatedContact = mutableContact.copy() as? CNContact {
                updateCachedContact(updatedContact)
            }

            return true
        } catch {
            handleError(error, message: "Failed to save contact image")
            return false
        }
    }

    func refreshContacts() async {
        guard hasContactsAccess else { return }
        guard !isRefreshing else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fetchedContacts = try await fetchContactsInBackground()
            processContacts(fetchedContacts)
        } catch {
            handleError(error, message: "Failed to refresh contacts")
        }
    }
}
