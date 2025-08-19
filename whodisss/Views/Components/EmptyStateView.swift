import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String?
    let iconColor: Color
    
    init(
        icon: String,
        title: String,
        message: String? = nil,
        iconColor: Color = .gray
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            if let message = message {
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "checkmark.circle",
        title: "All Done!",
        message: "All your contacts have profile photos",
        iconColor: .green
    )
}