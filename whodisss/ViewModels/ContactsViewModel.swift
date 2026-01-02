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
        guard authorizationStatus == .authorized else { return }

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
        var allContacts: [ContactInfo] = []
        var contactsWithoutImages: [ContactInfo] = []

        for contact in fetchedContacts {
            let hasImage = contact.imageDataAvailable && contact.imageData != nil
            let contactInfo = ContactInfo(contact: contact, hasImage: hasImage)

            allContacts.append(contactInfo)

            if !hasImage {
                contactsWithoutImages.append(contactInfo)
            }
        }

        self.contacts = allContacts.sorted { $0.displayName < $1.displayName }
        self.contactsWithoutImages = contactsWithoutImages.sorted { $0.displayName < $1.displayName }
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
            return true
        } catch {
            handleError(error, message: "Failed to save contact image")
            return false
        }
    }

    func refreshContacts() async {
        guard authorizationStatus == .authorized else { return }
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
