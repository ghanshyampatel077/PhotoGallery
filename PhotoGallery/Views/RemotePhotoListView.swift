import SwiftUI

struct RemotePhotoListView: View {
    let onInitialLoadFinished: (() -> Void)?

    @StateObject private var viewModel = RemotePhotoListViewModel()

    init(onInitialLoadFinished: (() -> Void)? = nil) {
        self.onInitialLoadFinished = onInitialLoadFinished
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.photos.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: AppConstants.UI.emptyPhotosTitle,
                        message: viewModel.errorMessage ?? AppConstants.UI.emptyPhotosMessage,
                        retryAction: viewModel.errorMessage == nil ? nil : {
                            Task { await viewModel.loadPhotos() }
                        }
                    )
                } else {
                    List(viewModel.photos) { photo in
                        RemotePhotoRowView(photo: photo)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.background)
                }
            }
            .navigationTitle(AppConstants.UI.photosTitle)
            .background(AppTheme.background.ignoresSafeArea())
            .overlay {
                if viewModel.isLoading && viewModel.photos.isEmpty {
                    ProgressView(AppConstants.UI.loadingPhotos)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .task {
                await viewModel.loadPhotos()
                onInitialLoadFinished?()
            }
        }
    }
}

private struct RemotePhotoRowView: View {
    let photo: PhotoDTO

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: displayImageURL(from: photo.thumbnailUrl, fallbackSize: 150))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: AppConstants.SystemImage.photo)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                default:
                    ProgressView()
                }
            }
            .frame(width: 72, height: 72)
            .background(AppTheme.brandGradient.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(photo.title.capitalized)
                    .font(.headline)
                    .lineLimit(2)
                Text(AppConstants.UI.albumNumber(Int64(photo.albumId)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppTheme.softShadow, radius: 8, x: 0, y: 4)
    }

    private func displayImageURL(from apiURL: String, fallbackSize: Int) -> String {
        guard
            let components = URLComponents(string: apiURL),
            components.host == AppConstants.ImageURL.placeholderHost
        else {
            return apiURL
        }

        let pathParts = components.path.split(separator: AppConstants.ImageURL.pathSeparator)
        let rawSize = pathParts.first.map(String.init) ?? AppConstants.ImageURL.emptyURL
        let size = Int(rawSize) ?? fallbackSize
        let color = pathParts.dropFirst().first.map(String.init) ?? AppConstants.ImageURL.defaultColor

        return AppConstants.ImageURL.replacementURL(size: size, color: color, photoID: photo.id)
    }
}
