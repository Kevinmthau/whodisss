import SwiftUI

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
        [contactName, companyName, location]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

#Preview {
    ImageSearchView(contactName: "John Doe", companyName: "Apple Inc.", location: "Cupertino, CA") { _ in }
}
