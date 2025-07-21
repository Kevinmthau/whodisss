import SwiftUI
import WebKit

struct ImageSearchView: View {
    let contactName: String
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                GoogleImageSearchWebView(
                    searchQuery: contactName,
                    isLoading: $isLoading,
                    onImageSelected: { image in
                        onImageSelected(image)
                        dismiss()
                    }
                )
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Google Images...")
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }
}

struct GoogleImageSearchWebView: UIViewRepresentable {
    let searchQuery: String
    @Binding var isLoading: Bool
    let onImageSelected: (UIImage) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "imageSelected")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.google.com/search?tbm=isch&q=\(encodedQuery)"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed - JavaScript is injected on page load
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler {
        let parent: GoogleImageSearchWebView
        
        init(_ parent: GoogleImageSearchWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            
            // Automatically inject JavaScript to handle image clicks
            webView.evaluateJavaScript("""
                // Remove existing listener if any
                if (window.imageSelectionHandler) {
                    document.removeEventListener('click', window.imageSelectionHandler, true);
                }
                
                // Add new click handler for all image clicks
                window.imageSelectionHandler = function(e) {
                    console.log('Click detected on page');
                    
                    var element = e.target;
                    var imageUrl = null;
                    
                    // Try to find image in clicked element or parents
                    var currentElement = element;
                    while (currentElement && !imageUrl) {
                        if (currentElement.tagName === 'IMG') {
                            imageUrl = currentElement.src;
                            break;
                        }
                        
                        // Check for background images
                        var style = window.getComputedStyle(currentElement);
                        var backgroundImage = style.backgroundImage;
                        if (backgroundImage && backgroundImage !== 'none') {
                            var match = backgroundImage.match(/url\\("(.+?)"\\)/);
                            if (match) {
                                imageUrl = match[1];
                                break;
                            }
                        }
                        
                        // Look for img tags in children
                        var imgChild = currentElement.querySelector('img');
                        if (imgChild) {
                            imageUrl = imgChild.src;
                            break;
                        }
                        
                        currentElement = currentElement.parentElement;
                    }
                    
                    if (imageUrl) {
                        console.log('Found image URL:', imageUrl);
                        // Prevent default navigation
                        e.preventDefault();
                        e.stopPropagation();
                        
                        // Send message to Swift
                        window.webkit.messageHandlers.imageSelected.postMessage(imageUrl);
                    }
                };
                
                document.addEventListener('click', window.imageSelectionHandler, true);
            """)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "imageSelected", let imageUrl = message.body as? String {
                print("Received image URL from JavaScript: \(imageUrl)")
                if let url = URL(string: imageUrl) {
                    downloadImage(from: url)
                }
            }
        }
        
        
        private func downloadImage(from url: URL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Download error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                guard let image = UIImage(data: data) else {
                    print("Failed to create image from data")
                    return
                }
                
                print("Successfully downloaded image")
                DispatchQueue.main.async {
                    self.parent.onImageSelected(image)
                }
            }.resume()
        }
    }
}

#Preview {
    ImageSearchView(contactName: "John Doe") { _ in }
}