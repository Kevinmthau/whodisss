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

    init(imageService: ImageServiceProtocol = ImageService()) {
        self.imageService = imageService
        super.init()
    }

    func setImageHandler(_ handler: @escaping (UIImage) -> Void) {
        self.onImageSelected = handler
    }

    func handleImageSelection(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showErrorMessage("Invalid image URL")
            return
        }

        Task {
            do {
                let image = try await imageService.downloadImage(from: url)
                onImageSelected?(image)
            } catch {
                handleError(error, message: "Failed to download image")
            }
        }
    }
}

extension ImageSearchViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        injectImageSelectionScript(into: webView)
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
