import Foundation
import Testing
import UIKit
@testable import whodisss

@MainActor
struct ImageSearchTests {
    @Test func latestSelectionIgnoresEarlierDownloadThatFinishesLast() async throws {
        let service = ControlledImageService()
        let viewModel = ImageSearchViewModel(imageService: service)
        var selectedImages: [UIImage] = []
        viewModel.setImageHandler { selectedImages.append($0) }
        let firstURL = URL(string: "https://example.com/first.jpg")!
        let latestURL = URL(string: "https://example.com/latest.jpg")!
        let firstTask = try #require(viewModel.handleImageSelection(from: firstURL.absoluteString))
        await service.downloads.waitForRequest(firstURL)
        let latestTask = try #require(viewModel.handleImageSelection(from: latestURL.absoluteString))
        await service.downloads.waitForRequest(latestURL)

        let latestImage = UIImage()
        await service.downloads.complete(latestURL, with: .success(latestImage))
        await latestTask.value
        await service.downloads.complete(firstURL, with: .success(UIImage()))
        await firstTask.value

        #expect(firstTask.isCancelled)
        #expect(selectedImages.count == 1)
        #expect(selectedImages.first === latestImage)
        #expect(!viewModel.showError)
        #expect(viewModel.handleImageSelection(from: firstURL.absoluteString) == nil)
    }

    @Test(arguments: [false, true])
    func cancelledSelectionCannotAffectReopenedSearch(downloadFails: Bool) async throws {
        let service = ControlledImageService()
        let viewModel = ImageSearchViewModel(imageService: service)
        var oldHandlerCalls = 0
        var newHandlerCalls = 0
        viewModel.setImageHandler { _ in oldHandlerCalls += 1 }
        let url = URL(string: "https://example.com/slow.jpg")!
        let task = try #require(viewModel.handleImageSelection(from: url.absoluteString))
        await service.downloads.waitForRequest(url)

        viewModel.cancelImageSelection()
        #expect(viewModel.handleImageSelection(from: url.absoluteString) == nil)
        viewModel.setImageHandler { _ in newHandlerCalls += 1 }
        let result: Result<UIImage, Error> = downloadFails
            ? .failure(URLError(.badServerResponse))
            : .success(UIImage())
        await service.downloads.complete(url, with: result)
        await task.value

        #expect(task.isCancelled)
        #expect(oldHandlerCalls == 0)
        #expect(newHandlerCalls == 0)
        #expect(!viewModel.showError)
    }

    @Test func failedDownloadAllowsRetryInTheSameSearch() async throws {
        let service = ControlledImageService()
        let viewModel = ImageSearchViewModel(imageService: service)
        var selectedImages: [UIImage] = []
        viewModel.setImageHandler { selectedImages.append($0) }
        let url = URL(string: "https://example.com/photo.jpg")!
        let failedTask = try #require(viewModel.handleImageSelection(from: url.absoluteString))
        await service.downloads.waitForRequest(url)
        await service.downloads.complete(url, with: .failure(URLError(.badServerResponse)))
        await failedTask.value

        #expect(viewModel.showError)
        #expect(selectedImages.isEmpty)

        viewModel.clearError()
        let retryTask = try #require(viewModel.handleImageSelection(from: url.absoluteString))
        await service.downloads.waitForRequest(url)
        let image = UIImage()
        await service.downloads.complete(url, with: .success(image))
        await retryTask.value

        #expect(selectedImages.count == 1)
        #expect(selectedImages.first === image)
        #expect(!viewModel.showError)
    }

    @Test(arguments: ["Jane Doe AT&T New York", "Taylor A+B", "Alex #1 / 50% & Co."])
    func searchURLPreservesTheEntireQuery(query: String) throws {
        let url = try #require(GoogleImageSearchWebView.searchURL(for: query))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "www.google.com")
        #expect(components.path == "/search")
        #expect(components.queryItems == [
            URLQueryItem(name: "tbm", value: "isch"),
            URLQueryItem(name: "q", value: query)
        ])
        #expect(components.fragment == nil)
        #expect(components.percentEncodedQuery?.contains("+") == false)
    }
}

private final class ControlledImageService: ImageServiceProtocol {
    let downloads = ControlledDownloads()

    func downloadImage(from url: URL) async throws -> UIImage {
        try await downloads.download(from: url)
    }

    func cropImageCentered(_ image: UIImage) -> UIImage { image }

    func cropImageWithTransform(_ image: UIImage, scale: CGFloat, offset: CGSize) -> UIImage { image }

    func compressImage(_ image: UIImage, quality: CGFloat) -> Data? { nil }
}

// Deliberately ignores cancellation so tests cover late network completions.
private actor ControlledDownloads {
    private var requests: [URL: CheckedContinuation<UIImage, Error>] = [:]
    private var requestWaiters: [URL: CheckedContinuation<Void, Never>] = [:]

    func download(from url: URL) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            requests[url] = continuation
            requestWaiters.removeValue(forKey: url)?.resume()
        }
    }

    func waitForRequest(_ url: URL) async {
        guard requests[url] == nil else { return }
        await withCheckedContinuation { continuation in
            requestWaiters[url] = continuation
        }
    }

    func complete(_ url: URL, with result: Result<UIImage, Error>) {
        requests.removeValue(forKey: url)?.resume(with: result)
    }
}
