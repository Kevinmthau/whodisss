import SwiftUI
import Combine

@MainActor
class SheetCoordinator: ObservableObject {
    @Published var activeSheet: ActiveSheet?
    private var pendingSheet: ActiveSheet?

    /// Present a sheet immediately if no sheet is active, otherwise queue it
    func present(_ sheet: ActiveSheet) {
        if activeSheet == nil {
            activeSheet = sheet
        } else {
            pendingSheet = sheet
        }
    }

    /// Dismiss the current sheet without presenting a pending sheet
    func dismiss() {
        pendingSheet = nil
        activeSheet = nil
    }

    /// Transition from current sheet to a new sheet
    func transitionTo(_ sheet: ActiveSheet) {
        pendingSheet = sheet
        activeSheet = nil
    }

    /// Called when a sheet is dismissed to handle pending sheet presentation
    func handleSheetDismissed() {
        if let pending = pendingSheet {
            pendingSheet = nil
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                activeSheet = pending
            }
        }
    }
}
