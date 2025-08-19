# Whodisss Architecture Overview

## Project Structure

The project follows the MVVM (Model-View-ViewModel) architectural pattern with clear separation of concerns:

```
whodisss/
├── Models/
│   └── ContactInfo.swift           # Contact data model with computed properties
│
├── Services/                       # Business logic and external interactions
│   ├── ContactStore.swift          # Contacts framework wrapper with protocol
│   └── ImageService.swift          # Image processing and download service
│
├── ViewModels/                     # Presentation logic and state management
│   ├── ContactsViewModel.swift     # Main contacts list state
│   ├── ContactDetailViewModel.swift # Individual contact management
│   └── ImageSearchViewModel.swift  # Web search coordination
│
├── Views/                          # UI components
│   ├── Components/                 # Reusable UI elements
│   │   ├── ContactRowView.swift    # List row display
│   │   ├── ContactAvatarView.swift # Profile image component
│   │   ├── LoadingView.swift       # Loading states
│   │   └── EmptyStateView.swift    # Empty/success states
│   │
│   ├── Contacts/                   # Contact-related screens
│   │   ├── ContactsListView.swift  # Main list screen
│   │   └── ContactDetailView.swift # Detail/edit screen
│   │
│   ├── Camera/                     # Camera functionality
│   │   └── CameraView.swift        # UIImagePickerController wrapper
│   │
│   ├── ImageSearch/                # Google Images search
│   │   └── ImageSearchView.swift   # WebView with JS injection
│   │
│   └── PhotoEditor/                # Photo editing
│       └── PhotoEditorView.swift   # Crop and prepare photos
│
├── ContentView.swift               # Root view
└── WhodisssApp.swift              # App entry point
```

## Key Design Patterns

### 1. Protocol-Oriented Design
- `ContactStoreProtocol` and `ImageServiceProtocol` enable dependency injection and testing
- Services can be mocked for unit tests

### 2. MVVM Architecture
- **Models**: Pure data structures with computed properties
- **ViewModels**: Handle business logic, state management, and data transformation
- **Views**: Purely presentational components with minimal logic

### 3. Dependency Injection
- ViewModels receive services through initializers
- Enables testability and flexibility

### 4. State Management
- `@StateObject` for ViewModel ownership
- `@ObservedObject` for shared ViewModels
- `@State` for local view state
- `@Published` properties for reactive updates

## Data Flow

1. **App Launch**
   - WhodisssApp → ContentView → ContactsListView
   - ContactsViewModel initializes with ContactStore dependency

2. **Contact Loading**
   - ContactsViewModel requests authorization from ContactStore
   - Contacts fetched on background thread via Task.detached
   - UI updates on main thread via @Published properties

3. **Photo Selection Flow**
   ```
   User Action → ContactDetailViewModel → Image Source
                                         ├── Camera
                                         ├── Photo Library
                                         └── Google Search
                                               ↓
                                         PhotoEditorView
                                               ↓
                                         Save to Contact
   ```

4. **Image Processing Pipeline**
   - Download (if from web) → Crop to Square → Compress → Save to Contact

## Threading Strategy

- **Main Thread**: All UI updates and ViewModel property changes
- **Background Thread**: Contact enumeration, image downloading
- **Task.detached**: Heavy contact loading operations
- **@MainActor**: Ensures ViewModel updates happen on main thread

## Error Handling

- Services throw errors for exceptional cases
- ViewModels catch and transform errors into user-friendly messages
- Alert presentation via `@Published showError` flags
- Graceful degradation for missing permissions

## Performance Optimizations

1. **Lazy Loading**: Contacts loaded on-demand
2. **Background Processing**: Heavy operations off main thread
3. **Image Compression**: 0.8 quality JPEG for storage efficiency
4. **Filtered Lists**: Separate arrays for contacts with/without images
5. **Minimal Re-renders**: Careful use of @Published properties

## Testing Considerations

- Protocol-based services enable easy mocking
- ViewModels can be tested independently of views
- Dependency injection allows for controlled test environments
- Clear separation of concerns simplifies unit testing

## Refresh Strategy

### Pull-to-Refresh
- Simple manual refresh via pull-down gesture
- Uses native SwiftUI `.refreshable` modifier
- No background processing or battery drain
- Complete user control over when to update

Implementation:
```swift
.refreshable {
    await viewModel.refreshContacts()
}
```

## Security & Privacy

- Contacts permission required and properly requested
- No data leaves device except for Google Images search
- Image data compressed before storage
- Proper Info.plist configuration for camera and contacts access
- No background monitoring or automatic refresh