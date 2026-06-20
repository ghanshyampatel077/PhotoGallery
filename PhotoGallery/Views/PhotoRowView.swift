import Kingfisher
import SwiftUI

struct PhotoRowView: View {
    // MARK: Input

    let photo: PhotoRowModel

    // MARK: Body
    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(photo.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(AppConstants.UI.albumNumber(photo.albumID))
                    Text(AppConstants.UI.photoNumber(photo.photoID))
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: AppConstants.SystemImage.chevronRight)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: AppTheme.softShadow, radius: 10, x: 0, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Subviews

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.brandGradient.opacity(0.20))

            KFImage(URL(string: photo.thumbnailURLString))
                .placeholder {
                    ProgressView()
                        .controlSize(.small)
                }
                .onFailureImage(PhotoPlaceholder.image)
                .resizable()
                .scaledToFill()
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
