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
        let script = """
            if (window.imageSelectionHandler) {
                document.removeEventListener('click', window.imageSelectionHandler, true);
            }

            window.imageSelectionHandler = function(e) {
                var element = e.target;
                var imageUrl = null;

                var currentElement = element;
                while (currentElement && !imageUrl) {
                    if (currentElement.tagName === 'IMG') {
                        imageUrl = currentElement.src;
                        break;
                    }

                    var style = window.getComputedStyle(currentElement);
                    var backgroundImage = style.backgroundImage;
                    if (backgroundImage && backgroundImage !== 'none') {
                        var match = backgroundImage.match(/url\\("(.+?)"\\)/);
                        if (match) {
                            imageUrl = match[1];
                            break;
                        }
                    }

                    var imgChild = currentElement.querySelector('img');
                    if (imgChild) {
                        imageUrl = imgChild.src;
                        break;
                    }

                    currentElement = currentElement.parentElement;
                }

                if (imageUrl) {
                    e.preventDefault();
                    e.stopPropagation();
                    window.webkit.messageHandlers.imageSelected.postMessage(imageUrl);
                }
            };

            document.addEventListener('click', window.imageSelectionHandler, true);
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Failed to inject JavaScript: \(error)")
            }
        }
    }
}

extension ImageSearchViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "imageSelected", let imageUrl = message.body as? String {
            handleImageSelection(from: imageUrl)
        }
    }
}
