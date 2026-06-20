import CoreData
import Foundation
import Observation

@MainActor
@Observable
final class PhotoListViewModel {
    
    // MARK: State
    private(set) var photos: [PhotoRowModel] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    var errorMessage: String?
    var showDeleteConfirmation = false
    var photoToDelete: PhotoRowModel?

    private let repository: PhotoRepositoryProtocol
    private var hasMorePages = true

    // MARK: Initialization
    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: Loading
    func loadInitial(forceReload: Bool = false) async {
        guard !isLoading else { return }
        guard forceReload || photos.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        resetPagination()

        do {
            try await loadNextPage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Data Cleanup
    func removeInvalidPhotos() {
        photos.removeAll { $0.objectID.isTemporaryID }
    }

    func updatePhotoTitle(photoID: Int64, title: String) {
        guard let index = photos.firstIndex(where: { $0.photoID == photoID }) else { return }
        photos[index] = photos[index].updatingTitle(title)
    }

    func removePhoto(photoID: Int64) {
        photos.removeAll { $0.photoID == photoID }
    }

    func loadNextPageIfNeeded(currentPhoto: PhotoRowModel) async {
        guard hasMorePages, !isLoadingMore, !isLoading else { return }
        guard let lastPhoto = photos.last, lastPhoto.objectID == currentPhoto.objectID else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            try await loadNextPage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Delete Flow
    func confirmDelete(_ photo: PhotoRowModel) {
        photoToDelete = photo
        showDeleteConfirmation = true
    }

    func deletePhotos(at offsets: IndexSet) {
        guard let index = offsets.first, photos.indices.contains(index) else { return }
        confirmDelete(photos[index])
    }

    func performDelete() {
        guard let photo = photoToDelete else { return }

        do {
            let photoID = photo.photoID
            let objectID = photo.objectID
            try repository.deletePhoto(id: photoID)
            photos.removeAll { $0.objectID == objectID || $0.photoID == photoID }
            removeInvalidPhotos()
            photoToDelete = nil
            showDeleteConfirmation = false
        } catch {
            errorMessage = error.localizedDescription
            showDeleteConfirmation = false
        }
    }

    func cancelDelete() {
        photoToDelete = nil
        showDeleteConfirmation = false
    }

    // MARK: Retry
    func retry() async {
        await loadInitial(forceReload: true)
    }

    // MARK: Pagination Helpers
    private func resetPagination() {
        photos = []
        hasMorePages = true
    }

    private func loadNextPage() async throws {
        var batch = try repository.fetchPhotos(
            limit: PhotoRepository.pageSize,
            offset: photos.count
        )

        if batch.isEmpty {
            let fetchedCount = try await repository.fetchNextPageFromAPI()
            if fetchedCount == 0 {
                hasMorePages = false
                return
            }

            batch = try repository.fetchPhotos(
                limit: PhotoRepository.pageSize,
                offset: photos.count
            )
        }

        guard !batch.isEmpty else {
            hasMorePages = false
            return
        }

        photos.append(contentsOf: batch.map(PhotoRowModel.init))
        hasMorePages = true
    }
}
