import CoreData
import SwiftUI

struct PhotoListView: View {
    
    // MARK: Dependencies
    private let repository: PhotoRepositoryProtocol
    private let onInitialLoadFinished: (() -> Void)?
    @State private var viewModel: PhotoListViewModel
    @State private var selectedPhotoRoute: PhotoRoute?

    // MARK: Initialization
    init(repository: PhotoRepositoryProtocol, onInitialLoadFinished: (() -> Void)? = nil) {
        self.repository = repository
        self.onInitialLoadFinished = onInitialLoadFinished
        _viewModel = State(initialValue: PhotoListViewModel(repository: repository))
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.photos.isEmpty && !viewModel.isLoading {
                    emptyContent
                } else {
                    photoList
                }
            }
            .navigationTitle(AppConstants.UI.photosTitle)
            .background(AppTheme.background.ignoresSafeArea())
            .overlay {
                if viewModel.isLoading && viewModel.photos.isEmpty {
                    loadingOverlay
                }
            }
            .alert(AppConstants.UI.error, isPresented: errorAlertBinding) {
                Button(AppConstants.UI.ok, role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(AppConstants.UI.deletePhotoQuestion, isPresented: deleteConfirmationBinding) {
                Button(AppConstants.UI.delete, role: .destructive) {
                    viewModel.performDelete()
                }
                Button(AppConstants.UI.cancel, role: .cancel) {
                    viewModel.cancelDelete()
                }
            } message: {
                Text(AppConstants.UI.deletePhotoMessage)
            }
            .task {
                await viewModel.loadInitial()
                onInitialLoadFinished?()
            }
            .onAppear {
                viewModel.removeInvalidPhotos()
            }
            .navigationDestination(item: $selectedPhotoRoute) { route in
                PhotoDestinationView(
                    route: route,
                    repository: repository,
                    onPhotoUpdated: { [weak viewModel] photoID, title in
                        viewModel?.updatePhotoTitle(photoID: photoID, title: title)
                    },
                    onPhotoDeleted: { [weak viewModel] photoID in
                        viewModel?.removePhoto(photoID: photoID)
                    }
                )
            }
        }
    }

    // MARK: Subviews
    private var photoList: some View {
            List {
                ForEach(viewModel.photos) { photo in
                    Button {
                        selectedPhotoRoute = PhotoRoute(photo: photo)
                    } label: {
                        PhotoRowView(photo: photo)
                    }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .task {
                    await viewModel.loadNextPageIfNeeded(currentPhoto: photo)
                }
            }
            .onDelete { indexSet in
                viewModel.deletePhotos(at: indexSet)
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.regular)
                        .padding(.vertical, 16)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private var emptyContent: some View {
        EmptyStateView(
            title: AppConstants.UI.emptyPhotosTitle,
            message: viewModel.errorMessage ?? AppConstants.UI.emptyPhotosMessage,
            retryAction: viewModel.errorMessage == nil ? nil : {
                Task { await viewModel.retry() }
            }
        )
    }

    private var loadingOverlay: some View {
        VStack(spacing: 14) {
            AppLogoMark(size: 58)
            ProgressView(AppConstants.UI.loadingPhotos)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppTheme.softShadow, radius: 16, x: 0, y: 10)
    }

    // MARK: Bindings
    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && !viewModel.photos.isEmpty },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showDeleteConfirmation },
            set: { isPresented in
                viewModel.showDeleteConfirmation = isPresented
                if !isPresented {
                    viewModel.cancelDelete()
                }
            }
        )
    }
}

// MARK: - Navigation

private struct PhotoRoute: Identifiable, Hashable {
    let objectID: NSManagedObjectID
    let photo: PhotoRowModel

    var id: NSManagedObjectID {
        objectID
    }

    init(photo: PhotoRowModel) {
        self.objectID = photo.objectID
        self.photo = photo
    }
}

private struct PhotoDestinationView: View {
    let route: PhotoRoute
    let repository: PhotoRepositoryProtocol
    let onPhotoUpdated: (Int64, String) -> Void
    let onPhotoDeleted: (Int64) -> Void

    var body: some View {
        if let photo = try? repository.fetchPhoto(objectID: route.objectID) {
            PhotoDetailView(
                photo: photo,
                repository: repository,
                initialTitle: route.photo.title,
                initialThumbnailURLString: route.photo.thumbnailURLString,
                onPhotoUpdated: onPhotoUpdated,
                onPhotoDeleted: onPhotoDeleted
            )
        } else {
            EmptyStateView(
                title: AppConstants.UI.emptyPhotosTitle,
                message: AppConstants.Errors.photoNotFound,
                retryAction: nil
            )
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoListView(repository: PhotoRepository(persistence: .preview))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
