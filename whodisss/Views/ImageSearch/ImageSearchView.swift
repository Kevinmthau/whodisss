import SwiftUI
import WebKit

struct ImageSearchView: View {
    let contactName: String
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImageSearchViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                GoogleImageSearchWebView(
                    searchQuery: contactName,
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
}

struct GoogleImageSearchWebView: UIViewRepresentable {
    let searchQuery: String
    let viewModel: ImageSearchViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(viewModel, name: "imageSelected")
        
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
}

#Preview {
    ImageSearchView(contactName: "John Doe") { _ in }
}