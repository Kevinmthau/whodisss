# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Whodisss is an iOS app built with SwiftUI that helps users add profile photos to their contacts. The app provides three methods for adding photos:
1. Search Google Images via embedded web view
2. Choose from photo library using PhotosPicker
3. Take photos using device camera

## Architecture

### Core Components

- **ContactDataManager**: Main data management class that handles Contacts framework integration, authorization, and CRUD operations
- **ContactInfo**: Data model wrapping CNContact with computed properties for display and image handling
- **ContactsListView**: Main list interface with filtering (all contacts vs missing photos only) and search functionality
- **ContactDetailView**: Individual contact management with photo source selection
- **ImageSearchView**: Google Images integration using WKWebView with JavaScript interaction
- **PhotoEditorView**: Basic crop functionality for profile photos

### Data Flow

1. App requests Contacts access via ContactDataManager
2. Contacts loaded and filtered into those with/without profile images
3. User selects contact → ContactDetailView → photo source selection
4. **Photo Library**: PhotosPicker → PhotoEditorView (photoPickerItem reset to nil after processing)
5. **Google Images**: JavaScript message handling → image download → PhotoEditorView
6. **Camera**: CameraView → PhotoEditorView
7. PhotoEditorView cropping → ContactDataManager.saveImageToContact → contacts refresh

### Key Dependencies

- **Contacts Framework**: Core contact management and authorization
- **PhotosUI**: Photo library picker integration
- **WebKit**: Google Images search via WKWebView
- **UIKit Integration**: Camera picker and image processing

## Development Commands

This is an Xcode project with standard iOS development workflow:
- Open `whodisss.xcodeproj` in Xcode
- Build and run using Xcode's standard controls (Cmd+R)
- No external package manager dependencies
- Uses iOS Simulator or physical device for testing

## Testing

- Unit tests: `whodisssTests/whodisssTests.swift` (uses Swift Testing framework, not XCTest)
- UI tests: `whodisssUITests/` directory (traditional XCTest)
- Run tests via Xcode Test Navigator or Cmd+U

## Key Technical Notes

- ContactDataManager uses @MainActor but moves heavy contact enumeration to background thread via Task.detached
- Camera functionality requires physical device (not available in simulator)  
- Contacts access requires user permission and proper Info.plist configuration
- Navigation bar customizations: Back button text globally hidden via UINavigationBarAppearance in WhodisssApp
- List styling: Uses PlainListStyle() with edge-to-edge layout for clean appearance
- Search functionality: Custom TextField with scrollDismissesKeyboard(.immediately) for better UX

### Google Images Integration
- Uses WKWebView with WKScriptMessageHandler for JavaScript-to-Swift communication
- JavaScript automatically injected on page load to intercept all image clicks
- JavaScript searches DOM for images in clicked elements and parent/child elements
- Complex click handling that searches for both <img> tags and CSS background images
- Image download via URLSession before passing to PhotoEditorView

### Photo Selection Fixes
- PhotosPicker: Must reset `photoPickerItem = nil` after processing to allow repeat selections
- Sheet presentation: Use `onChange(of: showingImageSearch)` to detect dismissal before showing PhotoEditorView
- Use `pendingPhotoEditor` state and `DispatchQueue.main.asyncAfter` with 0.3s delay for proper sheet transitions

### Image Processing
- Automatic square cropping for profile photos in PhotoEditorView
- cropImageToSquare() method handles center cropping to smallest dimension
- Image compression at 0.8 quality before saving to contacts

### Build Configuration
- Bundle ID: `com.mushpot.whodisss`
- Deployment Target: iOS 18.5
- Supports iPhone and iPad
- Version: 1.0 (build 1)