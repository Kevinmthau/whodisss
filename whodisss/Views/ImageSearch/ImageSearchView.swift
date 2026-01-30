import SwiftUI
import WebKit

struct ImageSearchView: View {
    let contactName: String
    let companyName: String?
    let location: String?
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImageSearchViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                GoogleImageSearchWebView(
                    searchQuery: buildSearchQuery(),
                    viewModel: viewModel
                )
                
                if viewModel.isLoading {
                    LoadingView("Loading Google Images...")
                        .background(Color.white)
                }
            }
            .navigationTitle("Search Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setImageHandler { image in
                onImageSelected(image)
                dismiss()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    private func buildSearchQuery() -> String {
        var parts = [contactName]
        if let company = companyName, !company.isEmpty {
            parts.append(company)
        }
        if let loc = location, !loc.isEmpty {
            parts.append(loc)
        }
        return parts.joined(separator: " ")
    }
}

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

        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/search?tbm=isch&q=\(encodedQuery)"

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(
            forName: ImageSelectionScript.messageHandlerName
        )
    }

    class Coordinator {
        let weakHandler: WeakScriptMessageHandler

        init(viewModel: ImageSearchViewModel) {
            self.weakHandler = WeakScriptMessageHandler(delegate: viewModel)
        }
    }
}

/// Weak wrapper to prevent strong reference cycle between WKUserContentController and delegate
class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
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

#Preview {
    ImageSearchView(contactName: "John Doe", companyName: "Apple Inc.", location: "Cupertino, CA") { _ in }
}