import SwiftUI

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            RemotePhotoListView(onInitialLoadFinished: dismissSplash)
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashScreenView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: AppConstants.Animation.splashMinimumDurationNanoseconds)
            dismissSplash()
        }
    }

    private func dismissSplash() {
        guard showSplash else { return }
        withAnimation(.easeInOut(duration: AppConstants.Animation.splashDismissDuration)) {
            showSplash = false
        }
    }
}

#Preview {
    ContentView()
}
