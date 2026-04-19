import SwiftUI

private struct ErrorAlertModifier<Handler: ErrorHandling>: ViewModifier {
    @ObservedObject var handler: Handler

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: Binding(
                get: { handler.showError },
                set: { handler.showError = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(handler.errorMessage ?? "An error occurred")
            }
    }
}

extension View {
    func errorAlert<Handler: ErrorHandling>(for handler: Handler) -> some View {
        modifier(ErrorAlertModifier(handler: handler))
    }
}
