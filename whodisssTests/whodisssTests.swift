import Contacts
import Testing
import UIKit
@testable import whodisss

struct whodisssTests {
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

    @Test func cropConfiguration_clampsScaleAndOffsetToFilledCrop() {
        let clampedScale = CropConfiguration.clampedScale(0.25)
        let clampedOffset = CropConfiguration.clampedOffset(
            CGSize(width: 500, height: 500),
            for: CGSize(width: 1200, height: 600),
            scale: clampedScale
        )

        #expect(clampedScale == CropConfiguration.minScale)
        #expect(clampedOffset.width == 120)
        #expect(clampedOffset.height == 0)
    }
}

private final class MockContactStore: ContactStoreProtocol {
    var authorizationStatus: CNAuthorizationStatus
    private var contactsSequence: [[CNContact]]
    private(set) var updateCallCount = 0

    init(authorizationStatus: CNAuthorizationStatus, contactsSequence: [[CNContact]]) {
        self.authorizationStatus = authorizationStatus
        self.contactsSequence = contactsSequence
    }

    func requestAccess() async throws -> Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    func fetchContacts() async throws -> [CNContact] {
        if contactsSequence.count > 1 {
            return contactsSequence.removeFirst()
        }

        return contactsSequence.first ?? []
    }

    func updateContact(_ contact: CNMutableContact) throws {
        updateCallCount += 1
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

private func makeContact(imageData: Data? = nil) -> CNContact {
    let contact = CNMutableContact()
    contact.givenName = "Taylor"
    contact.familyName = "Swift"
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
