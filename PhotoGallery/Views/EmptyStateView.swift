import SwiftUI

struct EmptyStateView: View {
    
    // MARK: Content
    let title: String
    let message: String
    var retryAction: (() -> Void)?

    // MARK: Body
    var body: some View {
        VStack(spacing: 16) {
            AppLogoMark(size: 82)

            Text(title)
                .font(.title3.weight(.semibold))

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let retryAction {
                Button(AppConstants.UI.retry, action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(AppTheme.background)
    }
}
