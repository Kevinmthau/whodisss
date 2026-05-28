import SwiftUI

struct SavingOverlay: View {
    let message: String

    init(_ message: String = "Saving photo...") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                Text(message)
                    .padding(.top)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

#Preview {
    SavingOverlay()
}
