import Foundation
import SwiftUI
import WebKit

@MainActor
class ImageSearchViewModel: NSObject, ObservableObject, ErrorHandling {
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showError = false

    private let imageService: ImageServiceProtocol
    private var onImageSelected: ((UIImage) -> Void)?
    private var downloadTask: Task<Void, Never>?
    private var selectionID: UUID?

    init(imageService: ImageServiceProtocol = ImageService()) {
        self.imageService = imageService
        super.init()
    }

    func setImageHandler(_ handler: @escaping (UIImage) -> Void) {
        cancelImageSelection()
        self.onImageSelected = handler
    }

    func cancelImageSelection() {
        selectionID = nil
        downloadTask?.cancel()
        downloadTask = nil
        onImageSelected = nil
    }

    @discardableResult
    func handleImageSelection(from urlString: String) -> Task<Void, Never>? {
        guard onImageSelected != nil else { return nil }
        guard let url = URL(string: urlString) else {
            showErrorMessage("Invalid image URL")
            return nil
        }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        downloadTask?.cancel()
        let selectionID = UUID()
        self.selectionID = selectionID
        let imageService = self.imageService

        let task = Task { [weak self] in
            do {
                let image = try await imageService.downloadImage(from: url)
                guard !Task.isCancelled, let self, self.selectionID == selectionID else { return }

                // Finish the search session before the callback starts the sheet transition.
                let handler = self.onImageSelected
                self.onImageSelected = nil
                self.selectionID = nil
                self.downloadTask = nil
                handler?(image)
            } catch {
                guard !Task.isCancelled, let self, self.selectionID == selectionID else { return }
                self.selectionID = nil
                self.downloadTask = nil
                self.handleError(error, message: "Failed to download image")
            }
        }
        downloadTask = task
        return task
    }
}

extension ImageSearchViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        injectImageSelectionScript(into: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        showErrorMessage("Failed to load search results")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        showErrorMessage("Failed to load search results")
    }

    private func injectImageSelectionScript(into webView: WKWebView) {
        webView.evaluateJavaScript(ImageSelectionScript.script) { _, error in
            if let error = error {
                print("Failed to inject JavaScript: \(error)")
            }
        }
    }
}

extension ImageSearchViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == ImageSelectionScript.messageHandlerName, let imageUrl = message.body as? String {
            handleImageSelection(from: imageUrl)
        }
    }
}
