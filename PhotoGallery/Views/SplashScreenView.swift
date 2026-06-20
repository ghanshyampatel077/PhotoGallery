import SwiftUI

struct SplashScreenView: View {
    // MARK: State

    @State private var logoScale = 0.82
    @State private var logoOpacity = 0.0
    @State private var ringRotation = 0.0
    @State private var titleOffset: CGFloat = 14
    @State private var titleOpacity = 0.0

    // MARK: Body

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .trim(from: 0.08, to: 0.86)
                        .stroke(
                            AppTheme.brandGradient,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 142, height: 142)
                        .rotationEffect(.degrees(ringRotation))
                        .opacity(0.76)

                    AppLogoMark(size: 104)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text(AppConstants.UI.appName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(AppConstants.UI.splashSubtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear(perform: startAnimation)
    }

    // MARK: Animation

    private func startAnimation() {
        withAnimation(.spring(response: 0.58, dampingFraction: 0.72)) {
            logoScale = 1
            logoOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.48).delay(0.16)) {
            titleOffset = 0
            titleOpacity = 1
        }

        withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
