import SwiftUI
import Contacts
import ContactsUI

struct ContactEditorWrapper: UIViewControllerRepresentable {
    let contact: CNContact
    @Binding var isPresented: Bool
    let onDismiss: (CNContact?) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        // Fetch contact with all required keys for CNContactViewController
        let store = CNContactStore()
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]

        guard let fullContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch) else {
            // If we can't fetch the full contact, create a basic view controller
            let controller = CNContactViewController()
            return UINavigationController(rootViewController: controller)
        }

        let controller = CNContactViewController(for: fullContact)
        controller.allowsEditing = true
        controller.allowsActions = false
        controller.delegate = context.coordinator

        // Add Cancel button
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: context.coordinator, action: #selector(Coordinator.cancelTapped))
        controller.navigationItem.leftBarButtonItem = cancelButton

        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactEditorWrapper

        init(_ parent: ContactEditorWrapper) {
            self.parent = parent
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.onDismiss(contact)
            parent.isPresented = false
        }

        @objc func cancelTapped() {
            parent.onDismiss(nil)
            parent.isPresented = false
        }
    }
}
