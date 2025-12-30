import Foundation
import Combine

/// Protocol for ViewModels that need error handling capabilities
protocol ErrorHandling: ObservableObject {
    var errorMessage: String? { get set }
    var showError: Bool { get set }
}

extension ErrorHandling {
    /// Display an error message to the user
    /// - Parameter message: The error message to display
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// Handle an error with an optional custom message
    /// - Parameters:
    ///   - error: The error that occurred (optional for cases without a thrown error)
    ///   - message: A user-friendly message describing what failed
    func handleError(_ error: Error?, message: String) {
        errorMessage = message
        showError = true

        if let error = error {
            print("\(message): \(error.localizedDescription)")
        }
    }

    /// Clear the current error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
