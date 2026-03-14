# AGENTS.md

## Project Summary

Whodisss is an iOS SwiftUI app for adding contact photos from:
- Google Images via `WKWebView`
- Photo library via `PhotosPicker`
- Device camera via `UIImagePickerController`

The app uses MVVM with protocol-based services:
- `Models/` for contact wrappers
- `Services/` for Contacts and image work
- `ViewModels/` for state and side effects
- `Views/` for SwiftUI/UIKit bridges

## Working Rules

- Keep view models `@MainActor`.
- Prefer injecting services through protocols for testability.
- Do not add multiple competing sheet modifiers for the photo flow.
- When saving a contact image, use the current `CNContact` instance from the active detail view, not an old snapshot.
- After a successful image save, keep `contacts` and `contactsWithoutImages` in sync immediately.
- Treat Contacts authorization `.limited` the same as usable read access.
- Guard camera presentation with `UIImagePickerController.isSourceTypeAvailable(.camera)`.

## UI Constraints

- The main contacts screen uses a bottom floating control area in `ContactsListView`.
- Keep the filter button on the bottom left.
- Keep search as a floating control beside the filter button.
- Do not use SwiftUI `Menu` as an overlay on top of the UIKit contact detail controller. It caused `_UIReparentingView` warnings and broken hierarchy behavior. Use `confirmationDialog`, sheet-based pickers, or custom SwiftUI overlays instead.
- Preserve enough bottom list inset so the final contact row does not sit under the floating controls.

## Photo Editing

- Crop behavior must keep the crop area fully covered by the image.
- Clamp both zoom and drag offsets with `CropConfiguration`.
- Export cropped images with the clamped transform.
- The app writes JPEG contact photos, so avoid transparent output assumptions.

## Image Search Notes

- `ImageSearchViewModel` owns `WKNavigationDelegate` and `WKScriptMessageHandler` behavior.
- Handle both provisional and committed web navigation failures.
- Google image results can emit unusable thumbnail or WebP-backed URLs. If you change image selection logic, prefer URLs that decode cleanly in UIKit.

## Tests

- Unit tests use Swift Testing in `whodisssTests/`.
- Add or update tests when changing:
  - authorization handling
  - contact save/list refresh behavior
  - crop bounds logic

## Build Notes

- The checked-in project currently targets iOS 26 in `project.pbxproj`.
- In restricted environments, `xcodebuild` may fail in asset compilation because `actool` wants simulator runtime services even when Swift compilation succeeds.
