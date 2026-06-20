# PhotoGallery

PhotoGallery is a Swift-based iOS application designed to display a curated gallery of photos. It features a modern, clean SwiftUI interface, a custom animated splash transition, and a robust Core Data setup for local data persistence.

Currently, the project is structured with a premium, brand-aligned design system and foundation. Here is a breakdown of what has been implemented so far.

---

## 🎨 Design & Theme

A significant focus has been placed on creating a premium user experience from the moment the app launches:

*   **Animated Splash Screen (`SplashScreenView.swift`)**: A customized, fluid launch sequence featuring a brand-gradient ring that rotates continuously, combined with scale and opacity animations on the app logo.
*   **Custom Vector Logomark (`AppLogoMark` inside `AppTheme.swift`)**: A bespoke, mathematically defined SwiftUI view representing a camera/aperture. It scales dynamically and uses HSL-tailored brand gradients and soft dropshadows.
*   **Color Palette (`AppTheme.swift`)**: Includes curated gradient backgrounds (soft teal to warm peach), dynamic card surfaces that support dark mode naturally, and clean drop-shadow specifications.

---

## 🛠️ Project Architecture & Foundation

The codebase is organized cleanly to enforce separation of concerns:

### 1. Centralized Configuration (`AppConstants.swift`)
To prevent magic numbers and hardcoded strings, all configurations are grouped in a `nonisolated enum AppConstants` which includes:
*   **Animations**: Precise durations for transitions and splash timings.
*   **API**: Endpoints for photo synchronization (targeting JSONPlaceholder).
*   **Core Data**: Constants for entity names, local predicate formatting, and memory store paths.
*   **UI Copy**: Reusable localized text for menus, screens, alerts, and placeholders.
*   **Image Handling**: Configuration for placeholders and URL-rewriters.

### 2. Core Data Layer (`Persistence.swift`)
A pre-configured Core Data container setup supporting:
*   **View Context Merging**: Automatically merges changes from parent contexts to keep the main thread updated.
*   **NSMergePolicy**: Configured to resolve write conflicts gracefully (`NSMergeByPropertyObjectTrumpMergePolicy`).
*   **Background Contexts**: A helper to spawn independent contexts for processing background operations (like API downloads) without blocking the UI.
*   **Custom Errors**: Mapping Core Data failures to human-readable localized errors.

### 3. Views & Layout
*   **`ContentView.swift`**: Controls the transition between the splash screen and the main application container. It uses a `ZStack` and coordinate transitions to fade out the splash screen after its minimum duration.
*   **`EmptyStateView.swift`**: A reusable view containing the custom brand logo, descriptive titles/messages, and support for a CTA button (like a "Retry" action).

---

## 📂 Project Structure

```
PhotoGallery/
├── PhotoGallery/
│   ├── PhotoGalleryApp.swift      # Application entry point
│   ├── ContentView.swift           # Main view coordinator and navigation shell
│   ├── AppConstants.swift          # App-wide static configuration and UI text
│   ├── Persistence.swift           # Core Data container setup and context helpers
│   ├── Assets.xcassets             # Assets (AppIcon, photo placeholder, etc.)
│   └── Views/
│       ├── AppTheme.swift          # Custom theme gradients, shadow, and vector logomark
│       ├── SplashScreenView.swift  # Animated launch screen
│       └── EmptyStateView.swift    # Reusable state view for empty/error screens
└── PhotoGallery.xcodeproj          # Xcode Project file (configured with synchronized groups)
```

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

No API keys, custom credentials, or complex setup tasks are required. The project references dependencies (like Kingfisher and IQKeyboardManager) via Swift Package Manager (SPM), which Xcode resolves automatically on launch.

---

## 🚀 Roadmap / Next Steps

1. **Core Data Entity**: Set up the `.xcdatamodeld` file defining the `Photo` entity (with attributes like `id`, `albumId`, `title`, `url`, and `thumbnailUrl`).
2. **Networking API Service**: Add `PhotoAPIService` to perform paginated network requests to the JSONPlaceholder photos endpoint.
3. **Repository Pattern**: Build a synchronization repository that checks the Core Data cache first, then fetches pages from the API when scrolling past cached records.
4. **Photo List View**: Replace the empty state in `ContentView` with a paginated, infinite-scrolling list of photos.
5. **Detail & Editing Screen**: Implement a detail view allowing full-size image viewing, editing the photo's title locally, and deleting a record.
