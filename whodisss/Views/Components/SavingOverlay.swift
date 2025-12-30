import SwiftUI

struct SavingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving photo...")
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
