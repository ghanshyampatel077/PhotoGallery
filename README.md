# PhotoGallery

PhotoGallery is a Swift-based iOS application designed to display a curated gallery of photos. It features a modern, clean SwiftUI interface, a custom animated splash transition, and a robust offline-first Core Data setup for local data persistence.

The project implements a complete synchronization architecture between a REST API and a local SQLite database, allowing the app to run completely offline, fetch paginated data on demand, and perform local title updates and deletions with transactional safety.

---

## 📸 Screenshots

Here is a visual walkthrough of the application:

<p align="center">
  <img src="/Users/ghanshyampatel/.gemini/antigravity/brain/a946c4e0-3100-40d8-9a50-bfa50478112d/media__1781967829833.png" width="19%" alt="Splash Screen" />
  <img src="/Users/ghanshyampatel/.gemini/antigravity/brain/a946c4e0-3100-40d8-9a50-bfa50478112d/media__1781967829827.png" width="19%" alt="Main Feed" />
  <img src="/Users/ghanshyampatel/.gemini/antigravity/brain/a946c4e0-3100-40d8-9a50-bfa50478112d/media__1781967829825.png" width="19%" alt="Swipe to Delete" />
  <img src="/Users/ghanshyampatel/.gemini/antigravity/brain/a946c4e0-3100-40d8-9a50-bfa50478112d/media__1781967829838.png" width="19%" alt="Detail View" />
  <img src="/Users/ghanshyampatel/.gemini/antigravity/brain/a946c4e0-3100-40d8-9a50-bfa50478112d/media__1781967829812.png" width="19%" alt="Delete Confirmation" />
</p>

*From left to right: (1) Animated Splash Screen, (2) Infinite-Scrolling Feed, (3) Swipe-to-Delete Action, (4) Photo Details & Edit Title Screen, (5) Deletion Confirmation Alert.*

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

## 🔍 Detail Screen & Title Editing

The detail view provides a workspace to view, edit, and manage individual photo objects:

*   **Interactive Zooming (`ZoomablePhotoView.swift`)**: Tapping the image opens a dedicated full-screen view where users can zoom and inspect details with pinch gestures.
*   **Caching & Asynchronous Loading**: Powered by Kingfisher (`KFImage`) to load and cache full-sized remote images and thumbnails.
*   **Local Title Editing**: Users can edit photo titles, which are trimmed and persisted to Core Data. Edits are immediately bubbled up to refresh the main feed.
*   **Double-Confirmation Alerts**: Both detail screen deletions and list swipe-to-delete triggers require confirmation using a standardized modal popup before permanently removing the record.

---

## 🛠️ Project Architecture

The app follows the **MVVM-R** (Model-View-ViewModel-Repository) design pattern:

```
Views (SwiftUI) 
  ├── ViewModels (ObservableObject / Observation)
  │     └── Repository (PhotoRepository)
  │           ├── Local Database (Core Data)
  │           └── Remote API Service (PhotoAPIService)
  └── Models (PhotoRowModel / PhotoDTO)
```

| Component | Responsibility |
| :--- | :--- |
| **Views** | SwiftUI detail screens, lists, row structures, and empty states (`ContentView`, `PhotoListView`, `PhotoDetailView`, `PhotoRowView`, `SplashScreenView`, `EmptyStateView`, `ZoomablePhotoView`). |
| **ViewModels** | Manages UI list states, pagination triggers, error mappings, validation, and detail updates (`PhotoListViewModel`, `PhotoDetailViewModel`). |
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
│   │   ├── PhotoListViewModel.swift      # Main list view model
│   │   └── PhotoDetailViewModel.swift    # Photo detail view model
│   └── Views/
│       ├── AppTheme.swift                # Gradients, cards, shadows, and vector app logo
│       ├── SplashScreenView.swift        # Animated splash screen view
│       ├── EmptyStateView.swift          # Custom empty and error state display
│       ├── PhotoListView.swift           # Infinite-scrolling SwiftUI photo list
│       ├── PhotoRowView.swift            # Row view using Kingfisher for image caching
│       ├── PhotoDetailView.swift         # Detail view with title editing and delete actions
│       ├── ZoomablePhotoView.swift       # Pinch-to-zoom interactive photo overlay
│       └── PhotoPlaceholder.swift        # Fallback image provider
└── PhotoGalleryTests/
    ├── PhotoAPIServiceTests.swift        # Network service tests
    ├── PhotoRepositoryTests.swift        # Repository integration tests (CRUD & pagination)
    └── PhotoViewModelTests.swift         # ViewModel validation tests
```

---

## 🧪 Unit Testing

The repository, networking, and view-model layers are fully tested under local in-memory databases and mocked API response providers:

*   **`PhotoRepositoryTests.swift`**: Verifies basic database CRUD, duplicate prevention (upserts), pagination advancement, and transactional batch deletion.
*   **`PhotoViewModelTests.swift`**: Assures that view-model states update correctly upon edits, and that delete confirmation alerts behave as expected during swipes.
*   **`PhotoAPIServiceTests.swift`**: Verifies query constructions, empty payloads, parsing, and non-200 HTTP responses.

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
