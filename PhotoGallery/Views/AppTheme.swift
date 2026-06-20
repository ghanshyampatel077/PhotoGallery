import SwiftUI

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.98, blue: 0.98),
            Color(red: 0.99, green: 0.96, blue: 0.93)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.58, blue: 0.64),
            Color(red: 0.24, green: 0.33, blue: 0.78),
            Color(red: 0.98, green: 0.42, blue: 0.32)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let softShadow = Color.black.opacity(0.10)
}

struct AppLogoMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(AppTheme.brandGradient)

            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(.white.opacity(0.34), lineWidth: max(size * 0.025, 2))
                .padding(size * 0.08)

            Circle()
                .fill(.white.opacity(0.94))
                .frame(width: size * 0.38, height: size * 0.38)
                .shadow(color: .black.opacity(0.14), radius: size * 0.04, x: 0, y: size * 0.025)

            Circle()
                .fill(AppTheme.brandGradient)
                .frame(width: size * 0.23, height: size * 0.23)

            RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
                .fill(.white.opacity(0.92))
                .frame(width: size * 0.28, height: size * 0.08)
                .offset(y: -size * 0.26)

            Circle()
                .fill(.white.opacity(0.86))
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(x: size * 0.25, y: -size * 0.19)
        }
        .frame(width: size, height: size)
        .shadow(color: AppTheme.softShadow, radius: size * 0.12, x: 0, y: size * 0.08)
    }
}
