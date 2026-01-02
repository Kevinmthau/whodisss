import SwiftUI
import Contacts
import ContactsUI

struct ContactViewControllerRepresentable: UIViewControllerRepresentable {
    let contact: CNContact
    let onBack: () -> Void
    let onContactUpdated: (CNContact) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]

        guard let fullContact = try? store.unifiedContact(
            withIdentifier: contact.identifier,
            keysToFetch: keysToFetch
        ) else {
            let emptyController = UIViewController()
            emptyController.view.backgroundColor = .systemBackground
            return UINavigationController(rootViewController: emptyController)
        }

        let controller = CNContactViewController(for: fullContact)
        controller.allowsEditing = true
        controller.allowsActions = true
        controller.delegate = context.coordinator

        // Add back button that dismisses to SwiftUI
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.backTapped)
        )
        controller.navigationItem.leftBarButtonItem = backButton

        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        context.coordinator.onBack = onBack
        context.coordinator.onContactUpdated = onContactUpdated
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBack: onBack, onContactUpdated: onContactUpdated)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var onContactUpdated: (CNContact) -> Void
        var onBack: () -> Void

        init(onBack: @escaping () -> Void, onContactUpdated: @escaping (CNContact) -> Void) {
            self.onBack = onBack
            self.onContactUpdated = onContactUpdated
        }

        @objc func backTapped() {
            onBack()
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            if let contact = contact {
                onContactUpdated(contact)
            }
        }
    }
}
