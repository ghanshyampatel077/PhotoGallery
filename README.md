# PhotoGallery

PhotoGallery is a Swift-based iOS application designed to display a curated gallery of photos. It features a modern, clean SwiftUI interface, a custom animated splash transition, and a robust Core Data setup for local data persistence.

Currently, the project is structured with a premium, brand-aligned design system and an active networking layer that fetches photos asynchronously from a REST API.

---

## 🎨 Design & Theme

A significant focus has been placed on creating a premium user experience from the moment the app launches:

*   **Animated Splash Screen (`SplashScreenView.swift`)**: A customized, fluid launch sequence featuring a brand-gradient ring that rotates continuously, combined with scale and opacity animations on the app logo.
*   **Custom Vector Logomark (`AppLogoMark` inside `AppTheme.swift`)**: A bespoke, mathematically defined SwiftUI view representing a camera/aperture. It scales dynamically and uses HSL-tailored brand gradients and soft dropshadows.
*   **Color Palette (`AppTheme.swift`)**: Includes curated gradient backgrounds (soft teal to warm peach), dynamic card surfaces that support dark mode naturally, and clean drop-shadow specifications.

---

## 📡 Networking & API Sync

The networking layer is implemented using modern Swift concurrency (`async/await`) and is designed to fetch, decode, and transform remote photo resources:

### 1. Data Model (`PhotoDTO.swift`)
*   Defines the `PhotoDTO` struct mapping JSON payloads from JSONPlaceholder.
*   Conforms to `Decodable`, `Identifiable`, and `Sendable` to support Swift's modern structured concurrency rules safely.

### 2. API Service (`PhotoAPIService.swift`)
*   Governed by the `PhotoAPIServiceProtocol` to facilitate dependency injection and mock-based testing.
*   Constructs paginated request URLs using query parameters (`_page` and `_limit`).
*   Processes requests asynchronously using `URLSession`.
*   Includes granular error states (`PhotoAPIError`) that map to user-friendly messages for invalid URLs, empty payloads, server status codes, underlying network failures, and JSON decoding issues.

### 3. Image URL Adaptation (`RemotePhotoListView.swift`)
*   Bypasses the slow and often unreliable `via.placeholder.com` service by dynamically rewriting image URLs to point to `placehold.co` while maintaining the identical dimensions, colors, and layout requested by the API.

---

## 🛠️ Project Architecture

The app follows the **MVVM** design pattern:

```
Views (SwiftUI) 
  ├── ViewModels (ObservableObject)
  │     └── Services (PhotoAPIService)
  └── Models (PhotoDTO)
```

| Component | Responsibility |
| :--- | :--- |
| **Views** | Renders UI components, controls transitions, and binds user inputs (`ContentView`, `RemotePhotoListView`, `SplashScreenView`, `EmptyStateView`). |
| **ViewModels** | Manages view state, orchestrates async data fetches, and handles loading and error states (`RemotePhotoListViewModel`). |
| **Services** | Performs network operations, validates HTTP responses, and handles JSON decoding (`PhotoAPIService`). |
| **Models** | Defines types for API response data transfer (`PhotoDTO`). |

---

## 📂 Project Structure

```
PhotoGallery/
├── PhotoGallery/
│   ├── PhotoGalleryApp.swift            # Application entry point
│   ├── ContentView.swift                 # Main view coordinator and splash flow controller
│   ├── AppConstants.swift                # App-wide static configurations, endpoints, and copy
│   ├── Persistence.swift                 # Core Data persistence container setup
│   ├── Assets.xcassets                   # UI assets (AccentColor, AppIcon, placeholders)
│   ├── Models/
│   │   └── PhotoDTO.swift                # Decodable photo model
│   ├── Services/
│   │   └── PhotoAPIService.swift         # REST API Service using URLSession
│   ├── ViewModels/
│   │   └── RemotePhotoListViewModel.swift # Remote photo list manager
│   └── Views/
│       ├── AppTheme.swift                # Gradients, cards, shadows, and vector app logo
│       ├── SplashScreenView.swift        # Animated splash screen view
│       ├── EmptyStateView.swift          # Custom empty and error state display
│       └── RemotePhotoListView.swift     # Paginated list showing online photos
└── PhotoGalleryTests/
    └── PhotoAPIServiceTests.swift        # Unit tests covering networking and error flows
```

---

## 🧪 Unit Testing

The networking layer is fully tested to ensure stability and reliability under various API responses:

*   **Mock Networking Protocol (`MockURLProtocol` inside `PhotoAPIServiceTests.swift`)**: Intercepts outgoing requests using native Foundation `URLProtocol` configuration to mock server states without making real HTTP requests.
*   **Verification Coverage**:
    *   `testFetchPhotosDecodesSuccessfulResponse`: Verifies correct URL query construction and successful JSON parsing.
    *   `testFetchPhotosThrowsServerErrorForNonSuccessfulStatus`: Ensures 5xx status codes are handled.
    *   `testFetchPhotosThrowsEmptyResponseForEmptySuccessfulBody`: Validates behavior when the API responds with empty data.

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

1. **Core Data Entity**: Define a local database schema mapping the fetched photo attributes.
2. **Local Sync Repository**: Build a synchronization repository that manages both offline Core Data storage and online REST API calls (displaying cached local data first, then fetching the next page only when scrolling past local limits).
3. **Local Actions (Edit & Delete)**: Allow users to edit photo titles locally and delete photos, reflecting these updates immediately in the scrolling feed.
