import SwiftUI
import WebKit

struct GoogleImageSearchWebView: UIViewRepresentable {
    let searchQuery: String
    let viewModel: ImageSearchViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(
            context.coordinator.weakHandler,
            name: ImageSelectionScript.messageHandlerName
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = viewModel

        if let url = Self.searchURL(for: searchQuery) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(
            forName: ImageSelectionScript.messageHandlerName
        )
    }

    private static func searchURL(for query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/search?tbm=isch&q=\(encoded)")
    }

    class Coordinator {
        let weakHandler: WeakScriptMessageHandler

        init(viewModel: ImageSearchViewModel) {
            self.weakHandler = WeakScriptMessageHandler(delegate: viewModel)
        }
    }
}

/// WKUserContentController retains its script message handlers strongly,
/// so we interpose a weak wrapper to avoid a cycle with the view model
/// that ultimately owns the web view.
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
