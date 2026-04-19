import SwiftUI
import Combine

@MainActor
class SheetCoordinator: ObservableObject {
    /// SwiftUI rejects a new `.sheet(item:)` presentation while the previous
    /// sheet is still animating out. `onDismiss` fires at the start of that
    /// animation, so we wait out the remainder before presenting the next.
    private static let transitionDelay: Duration = .milliseconds(100)

    @Published var activeSheet: ActiveSheet?
    private var pendingSheet: ActiveSheet?

    /// Present a sheet immediately if none is active, otherwise queue it.
    func present(_ sheet: ActiveSheet) {
        if activeSheet == nil {
            activeSheet = sheet
        } else {
            pendingSheet = sheet
        }
    }

    /// Dismiss the current sheet and drop any queued sheet.
    func dismiss() {
        pendingSheet = nil
        activeSheet = nil
    }

    /// Dismiss the current sheet and queue `sheet` for presentation once
    /// the dismiss animation completes.
    func transitionTo(_ sheet: ActiveSheet) {
        pendingSheet = sheet
        activeSheet = nil
    }

    /// Must be called from `.sheet`'s `onDismiss` so the queued sheet can
    /// take over.
    func handleSheetDismissed() {
        guard let next = pendingSheet else { return }
        pendingSheet = nil

        Task { @MainActor in
            try? await Task.sleep(for: Self.transitionDelay)
            guard activeSheet == nil else { return }
            activeSheet = next
        }
    }
}
