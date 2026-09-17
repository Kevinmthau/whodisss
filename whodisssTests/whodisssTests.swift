import Contacts
import Testing
import UIKit
@testable import whodisss

struct whodisssTests {
    @MainActor
    @Test func nativeContactEdits_updateBothCachesAndSortOrder() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let store = MockContactStore(authorizationStatus: .authorized, contactsSequence: [[alice, bob]])
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())
        await viewModel.loadContacts()

        let edited = try #require(alice.mutableCopy() as? CNMutableContact)
        edited.givenName = "Zoe"
        edited.imageData = makeImageData()
        viewModel.updateCachedContact(edited.copy() as! CNContact)

        #expect(viewModel.contacts.map(\.displayName) == ["Bob Baker", "Zoe Adams"])
        #expect(viewModel.contactsWithoutImages.map(\.id) == [bob.identifier])
        #expect(viewModel.contacts.last?.profileImage != nil)

        edited.imageData = nil
        viewModel.updateCachedContact(edited.copy() as! CNContact)

        #expect(viewModel.contacts.count == 2)
        #expect(viewModel.contactsWithoutImages.map(\.displayName) == ["Bob Baker", "Zoe Adams"])
        #expect(viewModel.contacts.last?.hasImage == false)
        #expect(store.updateCallCount == 0) // The native controller already saved the edit.
    }

    @MainActor
    @Test(arguments: [CNAuthorizationStatus.denied, .restricted])
    func requestContactsAccess_doesNotRepeatAnUnavailablePrompt(status: CNAuthorizationStatus) async {
        let store = MockContactStore(authorizationStatus: status, contactsSequence: [[makeContact()]])
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())

        await viewModel.requestContactsAccess()

        #expect(store.requestCallCount == 0)
        #expect(store.fetchCallCount == 0)
        #expect(viewModel.authorizationStatus == status)
        #expect(!viewModel.hasContactsAccess)
    }

    @MainActor
    @Test func requestContactsAccess_loadsNewlyGrantedLimitedContacts() async {
        let store = MockContactStore(authorizationStatus: .notDetermined, contactsSequence: [[makeContact()]])
        store.authorizationAfterRequest = .limited
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())

        await viewModel.requestContactsAccess()

        #expect(store.requestCallCount == 1)
        #expect(viewModel.authorizationStatus == .limited)
        #expect(viewModel.contacts.count == 1)
        #expect(!viewModel.isLoading)
    }

    @MainActor
    @Test func synchronizeContactsAccess_loadsAfterSettingsGrant() async {
        let store = MockContactStore(authorizationStatus: .denied, contactsSequence: [[makeContact()]])
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())
        await viewModel.synchronizeContactsAccess()
        #expect(store.fetchCallCount == 0)

        store.authorizationStatus = .limited
        await viewModel.synchronizeContactsAccess()

        #expect(viewModel.hasContactsAccess)
        #expect(viewModel.hasLoadedContacts)
        #expect(viewModel.contactsWithoutImages.count == 1)
        #expect(store.requestCallCount == 0)
    }

    @MainActor
    @Test func synchronizeContactsAccess_refreshesPreviouslyEmptyContacts() async {
        let newContact = makeContact()
        let store = MockContactStore(authorizationStatus: .authorized, contactsSequence: [[], [newContact]])
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())
        await viewModel.synchronizeContactsAccess()
        #expect(viewModel.hasLoadedContacts)
        #expect(viewModel.contacts.isEmpty)

        await viewModel.synchronizeContactsAccess()

        #expect(viewModel.contacts.map(\.id) == [newContact.identifier])
        #expect(viewModel.contactsWithoutImages.map(\.id) == [newContact.identifier])
        #expect(!viewModel.isRefreshing)
    }

    @MainActor
    @Test func refreshContacts_reloadsAnEmptyList() async {
        let store = MockContactStore(authorizationStatus: .authorized, contactsSequence: [[], [makeContact()]])
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())
        await viewModel.loadContacts()

        await viewModel.refreshContacts()

        #expect(viewModel.contacts.count == 1)
        #expect(viewModel.contactsWithoutImages.count == 1)
    }

    @MainActor
    @Test func synchronizeContactsAccess_clearsCachedContactsAfterRevocation() async {
        let contact = makeContact()
        let store = MockContactStore(authorizationStatus: .authorized, contactsSequence: [[contact]])
        let viewModel = ContactsViewModel(contactStore: store, imageService: MockImageService())
        await viewModel.loadContacts()
        viewModel.listScrollPositionID = contact.identifier

        store.authorizationStatus = .denied
        await viewModel.synchronizeContactsAccess()

        #expect(!viewModel.hasContactsAccess)
        #expect(!viewModel.hasLoadedContacts)
        #expect(viewModel.contacts.isEmpty)
        #expect(viewModel.contactsWithoutImages.isEmpty)
        #expect(viewModel.listScrollPositionID == nil)
        #expect(store.fetchCallCount == 1)
    }

    @MainActor
    @Test func loadContacts_acceptsLimitedAuthorization() async throws {
        let store = MockContactStore(
            authorizationStatus: .limited,
            contactsSequence: [[makeContact()]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()

        #expect(viewModel.hasContactsAccess)
        #expect(viewModel.contacts.count == 1)
    }

    @MainActor
    @Test func saveImageToContact_refreshesFilteredLists() async throws {
        let beforeSave = makeContact()
        let afterSave = makeContact(imageData: makeImageData())
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[beforeSave], [afterSave]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        #expect(viewModel.contactsWithoutImages.count == 1)

        let didSave = await viewModel.saveImageToContact(beforeSave, image: makeImage())

        #expect(didSave)
        #expect(store.updateCallCount == 1)
        #expect(viewModel.contacts.count == 1)
        #expect(viewModel.contactsWithoutImages.isEmpty)
        #expect(viewModel.contacts.first?.hasImage == true)
    }

    @MainActor
    @Test func saveImageToContact_anchorsMissingPhotosListToNextContact() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let charlie = makeContact(givenName: "Charlie", familyName: "Clark")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob, charlie]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didSave = await viewModel.saveImageToContact(bob, image: makeImage())

        #expect(didSave)
        #expect(viewModel.listScrollPositionID == charlie.identifier)
        #expect(viewModel.contactsWithoutImages.map(\.id) == [alice.identifier, charlie.identifier])
    }

    @MainActor
    @Test func saveImageToContact_anchorsMissingPhotosListToPreviousContactWhenSavingLast() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let charlie = makeContact(givenName: "Charlie", familyName: "Clark")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob, charlie]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didSave = await viewModel.saveImageToContact(charlie, image: makeImage())

        #expect(didSave)
        #expect(viewModel.listScrollPositionID == bob.identifier)
        #expect(viewModel.contactsWithoutImages.map(\.id) == [alice.identifier, bob.identifier])
    }

    @MainActor
    @Test func saveImageToContact_clearsMissingPhotosAnchorWhenSavingOnlyContact() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didSave = await viewModel.saveImageToContact(alice, image: makeImage())

        #expect(didSave)
        #expect(viewModel.listScrollPositionID == nil)
        #expect(viewModel.contactsWithoutImages.isEmpty)
    }

    @MainActor
    @Test func saveImageToContact_anchorsAllContactsListToSavedContact() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let charlie = makeContact(givenName: "Charlie", familyName: "Clark")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob, charlie]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        viewModel.showAllContacts()
        let didSave = await viewModel.saveImageToContact(bob, image: makeImage())

        #expect(didSave)
        #expect(viewModel.listScrollPositionID == bob.identifier)
        #expect(viewModel.contacts.map(\.id) == [alice.identifier, bob.identifier, charlie.identifier])
    }

    @MainActor
    @Test func deleteContact_removesContactFromContacts() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didDelete = await viewModel.deleteContact(alice)

        #expect(didDelete)
        #expect(store.deleteCallCount == 1)
        #expect(viewModel.contacts.map(\.id) == [bob.identifier])
    }

    @MainActor
    @Test func deleteContact_removesContactFromContactsWithoutImages() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didDelete = await viewModel.deleteContact(alice)

        #expect(didDelete)
        #expect(viewModel.contactsWithoutImages.map(\.id) == [bob.identifier])
    }

    @MainActor
    @Test func deleteContact_anchorsListScrollToNextVisibleContact() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let charlie = makeContact(givenName: "Charlie", familyName: "Clark")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob, charlie]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didDelete = await viewModel.deleteContact(bob)

        #expect(didDelete)
        #expect(viewModel.listScrollPositionID == charlie.identifier)
        #expect(viewModel.contactsWithoutImages.map(\.id) == [alice.identifier, charlie.identifier])
    }

    @MainActor
    @Test func deleteContact_anchorsListScrollToPreviousVisibleContactWhenDeletingLast() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let bob = makeContact(givenName: "Bob", familyName: "Baker")
        let charlie = makeContact(givenName: "Charlie", familyName: "Clark")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice, bob, charlie]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didDelete = await viewModel.deleteContact(charlie)

        #expect(didDelete)
        #expect(viewModel.listScrollPositionID == bob.identifier)
        #expect(viewModel.contactsWithoutImages.map(\.id) == [alice.identifier, bob.identifier])
    }

    @MainActor
    @Test func deleteContact_clearsListScrollAnchorWhenDeletingOnlyVisibleContact() async throws {
        let alice = makeContact(givenName: "Alice", familyName: "Adams")
        let store = MockContactStore(
            authorizationStatus: .authorized,
            contactsSequence: [[alice]]
        )
        let viewModel = ContactsViewModel(
            contactStore: store,
            imageService: MockImageService()
        )

        await viewModel.loadContacts()
        let didDelete = await viewModel.deleteContact(alice)

        #expect(didDelete)
        #expect(viewModel.listScrollPositionID == nil)
        #expect(viewModel.contacts.isEmpty)
        #expect(viewModel.contactsWithoutImages.isEmpty)
    }

    @Test func cropConfiguration_allowsShrinkingImageToFitCircle() {
        let imageSize = CGSize(width: 1200, height: 600) // aspect ratio 2:1
        let minScale = CropConfiguration.minScale(for: imageSize)

        // Users must be able to zoom out past the "fill" point (scale 1.0).
        #expect(minScale < 1.0)

        // At the minimum scale the entire image fits within the circular crop, i.e. its
        // rendered bounding box diagonal is no larger than the crop circle's diameter.
        let rendered = CropConfiguration.renderedImageSize(for: imageSize, scale: minScale)
        let diagonal = (rendered.width * rendered.width + rendered.height * rendered.height).squareRoot()
        #expect(diagonal <= CropConfiguration.cropSize + 0.001)

        // Requesting an even smaller scale clamps back up to the fit minimum.
        #expect(CropConfiguration.clampedScale(0.1, for: imageSize) == minScale)

        // Fully zoomed out the image is centered with no panning room.
        let clampedOffset = CropConfiguration.clampedOffset(
            CGSize(width: 500, height: 500),
            for: imageSize,
            scale: minScale
        )
        #expect(clampedOffset.width == 0)
        #expect(clampedOffset.height == 0)
    }

    @Test func cropConfiguration_clampsOffsetToFilledCropWhenZoomedIn() {
        let clampedOffset = CropConfiguration.clampedOffset(
            CGSize(width: 500, height: 500),
            for: CGSize(width: 1200, height: 600),
            scale: 1.0
        )

        #expect(clampedOffset.width == 120)
        #expect(clampedOffset.height == 0)
    }

    @Test func companyName_prefersOrganizationOverEmailDomain() {
        let contact = ContactInfo(
            contact: makeContact(organizationName: "Acme Corp", emails: ["taylor@globex.com"]),
            hasImage: false
        )

        #expect(contact.companyName == "Acme Corp")
    }

    @Test func companyName_fallsBackToCapitalizedEmailDomainPrefix() {
        let contact = ContactInfo(
            contact: makeContact(emails: ["taylor@globex.co.uk"]),
            hasImage: false
        )

        #expect(contact.companyName == "Globex")
    }

    @Test func companyName_skipsGmailAddresses() {
        let gmailOnly = ContactInfo(
            contact: makeContact(emails: ["taylor@gmail.com"]),
            hasImage: false
        )
        let gmailFirst = ContactInfo(
            contact: makeContact(emails: ["taylor@Gmail.com", "taylor@initech.io"]),
            hasImage: false
        )
        let gmailTrailingDot = ContactInfo(
            contact: makeContact(emails: ["taylor@gmail.com."]),
            hasImage: false
        )

        #expect(gmailOnly.companyName == nil)
        #expect(gmailFirst.companyName == "Initech")
        #expect(gmailTrailingDot.companyName == nil)
    }

    @Test func companyName_isNilWithoutOrganizationOrEmail() {
        let contact = ContactInfo(contact: makeContact(), hasImage: false)

        #expect(contact.companyName == nil)
    }

    @Test func companyName_rejectsMalformedEmails() {
        let doubleAt = ContactInfo(contact: makeContact(emails: ["a@@b.com"]), hasImage: false)
        let emptyLocalPart = ContactInfo(contact: makeContact(emails: ["@acme.com"]), hasImage: false)
        let noDomain = ContactInfo(contact: makeContact(emails: ["john@"]), hasImage: false)

        #expect(doubleAt.companyName == nil)
        #expect(emptyLocalPart.companyName == nil)
        #expect(noDomain.companyName == nil)
    }

    @Test func companyName_trimsWhitespaceAroundEmail() {
        let padded = ContactInfo(contact: makeContact(emails: [" taylor@globex.com "]), hasImage: false)

        #expect(padded.companyName == "Globex")
    }

    @Test func contactsListFilter_matchesCompanyName() {
        let acme = ContactInfo(
            contact: makeContact(givenName: "Ada", familyName: "Lovelace", emails: ["ada@acme.com"]),
            hasImage: false
        )
        let globex = ContactInfo(
            contact: makeContact(givenName: "Bob", familyName: "Baker", organizationName: "Globex"),
            hasImage: false
        )

        var filter = ContactsListFilter()
        filter.mode = .allContacts

        filter.searchText = "acme"
        #expect(filter.displayedContacts(
            allContacts: [acme, globex],
            contactsWithoutImages: []
        ).map(\.displayName) == ["Ada Lovelace"])

        filter.searchText = "globex"
        #expect(filter.displayedContacts(
            allContacts: [acme, globex],
            contactsWithoutImages: []
        ).map(\.displayName) == ["Bob Baker"])
    }

    @Test func contactsListFilter_usesModeAndSearchTextWithoutResorting() {
        let contactWithoutImage = ContactInfo(
            contact: makeContact(givenName: "Taylor", familyName: "Swift"),
            hasImage: false
        )
        let contactWithImage = ContactInfo(
            contact: makeContact(givenName: "Olivia", familyName: "Rodrigo"),
            hasImage: true
        )
        let allContacts = [contactWithImage, contactWithoutImage]
        let contactsWithoutImages = [contactWithoutImage]

        var filter = ContactsListFilter()

        #expect(filter.displayedContacts(
            allContacts: allContacts,
            contactsWithoutImages: contactsWithoutImages
        ).map(\.displayName) == ["Taylor Swift"])

        filter.mode = .allContacts
        #expect(filter.displayedContacts(
            allContacts: allContacts,
            contactsWithoutImages: contactsWithoutImages
        ).map(\.displayName) == ["Olivia Rodrigo", "Taylor Swift"])

        filter.searchText = "swift"
        #expect(filter.displayedContacts(
            allContacts: allContacts,
            contactsWithoutImages: contactsWithoutImages
        ).map(\.displayName) == ["Taylor Swift"])
    }
}

private final class MockContactStore: ContactStoreProtocol {
    var authorizationStatus: CNAuthorizationStatus
    var authorizationAfterRequest: CNAuthorizationStatus?
    private var contactsSequence: [[CNContact]]
    private(set) var requestCallCount = 0
    private(set) var fetchCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var deleteCallCount = 0

    init(authorizationStatus: CNAuthorizationStatus, contactsSequence: [[CNContact]]) {
        self.authorizationStatus = authorizationStatus
        self.contactsSequence = contactsSequence
    }

    func requestAccess() async throws -> Bool {
        requestCallCount += 1
        if let authorizationAfterRequest {
            authorizationStatus = authorizationAfterRequest
        }
        return authorizationStatus == .authorized || authorizationStatus == .limited
    }

    func fetchContacts() async throws -> [CNContact] {
        fetchCallCount += 1
        if contactsSequence.count > 1 {
            return contactsSequence.removeFirst()
        }

        return contactsSequence.first ?? []
    }

    func updateContact(_ contact: CNMutableContact) throws {
        updateCallCount += 1
    }

    func deleteContact(_ contact: CNMutableContact) throws {
        deleteCallCount += 1
    }
}

private final class MockImageService: ImageServiceProtocol {
    func downloadImage(from url: URL) async throws -> UIImage {
        makeImage()
    }

    func cropImageCentered(_ image: UIImage) -> UIImage {
        image
    }

    func cropImageWithTransform(_ image: UIImage, scale: CGFloat, offset: CGSize) -> UIImage {
        image
    }

    func compressImage(_ image: UIImage, quality: CGFloat) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}

private func makeContact(
    givenName: String = "Taylor",
    familyName: String = "Swift",
    organizationName: String = "",
    emails: [String] = [],
    imageData: Data? = nil
) -> CNContact {
    let contact = CNMutableContact()
    contact.givenName = givenName
    contact.familyName = familyName
    contact.organizationName = organizationName
    contact.emailAddresses = emails.map {
        CNLabeledValue(label: CNLabelWork, value: $0 as NSString)
    }
    contact.imageData = imageData
    return contact.copy() as! CNContact
}

private func makeImage() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
}

private func makeImageData() -> Data {
    makeImage().jpegData(compressionQuality: 1.0)!
}
