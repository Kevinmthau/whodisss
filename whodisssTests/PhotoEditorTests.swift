import Contacts
import Testing
import UIKit
@testable import whodisss

@MainActor
struct PhotoEditorTests {
    @Test func failedSavePreservesCropAndSelectionForSuccessfulRetry() async {
        let store = PhotoEditorContactStore()
        let contactsViewModel = ContactsViewModel(contactStore: store)
        let detailViewModel = ContactDetailViewModel(contactsViewModel: contactsViewModel)
        let image = makeEditorImage()
        let editor = PhotoEditorViewModel(originalImage: image, imageService: ImageService())
        let contact = CNMutableContact()
        contact.givenName = "Taylor"

        detailViewModel.selectedImage = image
        editor.scale = 2
        editor.offset = CGSize(width: 20, height: -10)
        let save: @MainActor (UIImage) async -> Bool = { croppedImage in
            await detailViewModel.saveEditedImage(croppedImage, for: contact)
        }
        let failureMessage: @MainActor () -> String? = { detailViewModel.errorMessage }

        let firstResult = await editor.saveImage(onSave: save, failureMessage: failureMessage)

        #expect(!firstResult)
        #expect(!editor.isSaving)
        #expect(editor.scale == 2)
        #expect(editor.offset == CGSize(width: 20, height: -10))
        #expect(detailViewModel.selectedImage === image)
        #expect(editor.showError)
        #expect(editor.errorMessage == "Failed to save contact image")
        #expect(!detailViewModel.showError)
        #expect(!contactsViewModel.showError)
        #expect(contactsViewModel.errorMessage == nil)

        store.shouldFail = false
        let retryResult = await editor.saveImage(onSave: save, failureMessage: failureMessage)

        #expect(retryResult)
        #expect(!editor.isSaving)
        #expect(!editor.showError)
        #expect(editor.errorMessage == nil)
        #expect(detailViewModel.selectedImage == nil)
        #expect(store.attemptedImageData.count == 2)
        #expect(store.attemptedImageData.first == store.attemptedImageData.last)
    }

    @Test func saveRemainsInProgressUntilPersistenceCompletesAndRejectsDuplicate() async {
        let editor = PhotoEditorViewModel(originalImage: makeEditorImage(), imageService: ImageService())
        let started = AsyncStream<Void>.makeStream()
        var saveCompletion: CheckedContinuation<Bool, Never>?
        let saveTask = Task {
            await editor.saveImage(onSave: { _ in
                await withCheckedContinuation { continuation in
                    saveCompletion = continuation
                    started.continuation.yield(())
                }
            })
        }

        for await _ in started.stream { break }
        started.continuation.finish()
        #expect(editor.isSaving)

        let duplicateResult = await editor.saveImage(onSave: { _ in
            Issue.record("A second save must not reach persistence while the first save is pending")
            return true
        })

        #expect(!duplicateResult)
        #expect(editor.isSaving)
        saveCompletion?.resume(returning: true)

        let result = await saveTask.value
        #expect(result)
        #expect(!editor.isSaving)
        #expect(!editor.showError)
    }
}

private final class PhotoEditorContactStore: ContactStoreProtocol {
    let authorizationStatus: CNAuthorizationStatus = .authorized
    var shouldFail = true
    private(set) var attemptedImageData: [Data] = []

    func requestAccess() async throws -> Bool { true }
    func fetchContacts() async throws -> [CNContact] { [] }

    func updateContact(_ contact: CNMutableContact) throws {
        if let imageData = contact.imageData {
            attemptedImageData.append(imageData)
        }
        if shouldFail {
            throw NSError(domain: "PhotoEditorTests", code: 1)
        }
    }

    func deleteContact(_ contact: CNMutableContact) throws { }
}

private func makeEditorImage() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 100, height: 80)).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 80))
        UIColor.systemRed.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
    }
}
