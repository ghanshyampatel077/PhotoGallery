import CoreData
import SwiftUI

struct RootView: View {
    
    // MARK: Dependencies
    let repository: PhotoRepositoryProtocol

    // MARK: State
    @State private var showSplash = true
    @State private var didFinishMinimumSplashTime = false
    @State private var didFinishInitialPhotoLoad = false

    // MARK: Body
    var body: some View {
        ZStack {
            PhotoListView(
                repository: repository,
                onInitialLoadFinished: {
                    didFinishInitialPhotoLoad = true
                    dismissSplashIfReady()
                }
            )
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashScreenView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: AppConstants.Animation.splashMinimumDurationNanoseconds)
            didFinishMinimumSplashTime = true
            dismissSplashIfReady()
        }
    }

    // MARK: Splash Coordination
    private func dismissSplashIfReady() {
        guard showSplash, didFinishMinimumSplashTime, didFinishInitialPhotoLoad else { return }

        withAnimation(.easeInOut(duration: AppConstants.Animation.splashDismissDuration)) {
            showSplash = false
        }
    }
}

struct ContentView: View {
    
    // MARK: Dependencies
    private let repository: PhotoRepositoryProtocol

    // MARK: Initialization
    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: Body
    var body: some View {
        RootView(repository: repository)
    }
}

// MARK: - Preview
#Preview {
    ContentView(repository: PhotoRepository(persistence: .preview))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
