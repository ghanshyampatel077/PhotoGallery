# PhotoGallery

PhotoGallery is a Swift-based iOS application designed to display a curated gallery of photos. It features a modern, clean SwiftUI interface, a custom animated splash transition, and a robust offline-first Core Data setup for local data persistence.

The project implements a complete synchronization architecture between a REST API and a local SQLite database, allowing the app to run completely offline.

---

## 🎨 Design & Theme

A significant focus has been placed on creating a premium user experience from the moment the app launches:

*   **Animated Splash Screen (`SplashScreenView.swift`)**: A customized, fluid launch sequence featuring a brand-gradient ring that rotates continuously, combined with scale and opacity animations on the app logo.
*   **Custom Vector Logomark (`AppLogoMark` inside `AppTheme.swift`)**: A bespoke, mathematically defined SwiftUI view representing a camera/aperture. It scales dynamically and uses HSL-tailored brand gradients and soft dropshadows.
*   **Color Palette (`AppTheme.swift`)**: Includes curated gradient backgrounds (soft teal to warm peach), dynamic card surfaces that support dark mode naturally, and clean drop-shadow specifications.

---

## 💾 Core Data & Persistence Layer

The app uses Core Data for offline storage and state persistence, utilizing a SQLite database:

### 1. Database Schema (`PhotoGallery.xcdatamodeld`)
*   Defines the `Photo` managed object entity.
*   Attributes: `id` (Integer 64), `albumId` (Integer 64), `title` (String), `url` (String), and `thumbnailUrl` (String).

### 2. Stack Setup (`Persistence.swift`)
*   **Conflict Resolution**: Configured with `NSMergeByPropertyObjectTrumpMergePolicy` so that newly fetched API data overrides old data without duplicating records.
*   **UI Merging**: Automatically merges changes made on background contexts directly into the main thread view context.
*   **Startup Failure Handling**: If the database fails to initialize (e.g. disk corruption), the app lifecycle gracefully catches the error and displays a structured system error screen.

---

## 📡 Synchronization Repository Pattern

Data coordination is governed by `PhotoRepository.swift` under the `PhotoRepositoryProtocol` contract:

*   **Offline-First Strategy**: When the user scrolls, the app queries the local Core Data database first. It only calls the network API if the user scrolls past the boundaries of locally cached pages.
*   **Background Upserting**: New network pages are saved asynchronously on a private background context. This prevents UI stuttering while parsing and persisting large batches of photo records.
*   **Pagination Progress (`UserDefaults`)**: Progress is tracked using dynamic, store-scoped keys in `UserDefaults` to avoid re-fetching pages from the API when the app is relaunched.
*   **Duplicate Prevention**: Network items are matched against existing records by `id` using an `IN` predicate block. This allows the repository to run bulk "upserts" (inserting new records and updating existing titles if they haven't been modified locally).
*   **Atomic Batch Deletion**: Supports removing individual photos or bulk-deleting multiple items. If one item in a deletion batch is missing, the operation rolls back to guarantee database consistency.

---

## 🛠️ Project Architecture

The app follows the **MVVM-R** (Model-View-ViewModel-Repository) design pattern:

```
Views (SwiftUI) 
  ├── ViewModels (ObservableObject)
  │     └── Repository (PhotoRepository)
  │           ├── Local Database (Core Data)
  │           └── Remote API Service (PhotoAPIService)
  └── Models (PhotoRowModel / PhotoDTO)
```

| Component | Responsibility |
| :--- | :--- |
| **Views** | SwiftUI rows, lists, and empty screens (`ContentView`, `PhotoListView`, `PhotoRowView`, `SplashScreenView`, `EmptyStateView`). |
| **ViewModels** | Manages UI list states, pagination triggers, error mappings, and deletion confirmations (`PhotoListViewModel`). |
| **Repository** | Coordinates CRUD operations between local Core Data cache and remote network calls (`PhotoRepository`). |
| **Services** | Performs network operations, validates HTTP responses, and handles JSON decoding (`PhotoAPIService`). |
| **Models** | Immutable structures mapped to views (`PhotoRowModel`) and API entities (`PhotoDTO`). |

---

## 📂 Project Structure

```
PhotoGallery/
├── PhotoGallery/
│   ├── PhotoGalleryApp.swift            # Application entry point & Core Data integration
│   ├── ContentView.swift                 # Main view coordinator and splash flow controller
│   ├── AppConstants.swift                # App-wide static configurations, endpoints, and copy
│   ├── Persistence.swift                 # Core Data container setup and context helpers
│   ├── PhotoGallery.xcdatamodeld         # Core Data model definitions
│   ├── Assets.xcassets                   # UI assets (AccentColor, AppIcon, placeholders)
│   ├── Models/
│   │   ├── PhotoDTO.swift                # Decodable API model
│   │   └── PhotoRowModel.swift           # Immutable view-layer photo model
│   ├── Services/
│   │   ├── PhotoAPIService.swift         # REST API Service using URLSession
│   │   └── PhotoRepository.swift         # Synchronization repository (Core Data + API)
│   ├── ViewModels/
│   │   └── PhotoListViewModel.swift      # Main list view model
│   └── Views/
│       ├── AppTheme.swift                # Gradients, cards, shadows, and vector app logo
│       ├── SplashScreenView.swift        # Animated splash screen view
│       ├── EmptyStateView.swift          # Custom empty and error state display
│       ├── PhotoListView.swift           # Infinite-scrolling SwiftUI photo list
│       ├── PhotoRowView.swift            # Row view using Kingfisher for image caching
│       └── PhotoPlaceholder.swift        # Fallback image provider
└── PhotoGalleryTests/
    ├── PhotoAPIServiceTests.swift        # Network service tests
    └── PhotoRepositoryTests.swift        # Repository integration tests (CRUD & pagination)
```

---

## 🧪 Unit Testing

The repository and networking layers are fully tested under local in-memory databases and mocked API response providers:

*   **`PhotoRepositoryTests.swift`**:
    *   `testFetchUpdateAndDeletePhoto`: Assures that fetching, title editing, and deletion operations work correctly.
    *   `testUpsertPreventsDuplicatePhotoIDs`: Verifies that unique constraints are respected during synchronization.
    *   `testFetchNextPageAdvancesPagination`: Validates that pagination counts advance correctly.
    *   `testFetchNextPageContinuesAfterAllLocalRowsAreDeleted`: Verifies that pagination index doesn't reset or duplicate when local items are cleared.
    *   `testBatchDeleteIsAtomicWhenAnyPhotoIsMissing`: Tests transactional safety in bulk deletions.

---

## ⚙️ Development Setup

### Requirements
*   **Xcode 16.0+** (configured with the iOS 16.0+ deployment target)
*   **macOS Sequoia or later**

### Running the App
1. Clone this repository to your local system.
2. Open `PhotoGallery.xcodeproj` in Xcode.
3. Select your target simulator (e.g., iPhone 15 or newer).
4. Run the project using `Command + R` (⌘R).

### Running the Tests
*   Press `Command + U` (⌘U) in Xcode to execute the unit test suite.

---

## 🚀 Roadmap / Next Steps

1. **Detail View**: Build `PhotoDetailView` to showcase the full-size image, show detailed photo parameters (album/photo indexes), and host actions to edit the title and delete the photo.
2. **Detail ViewModel**: Build `PhotoDetailViewModel` to process edits, interact with the repository, and bubble up data changes to refresh the parent list view.
