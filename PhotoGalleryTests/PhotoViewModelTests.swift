import CoreData
import XCTest
@testable import PhotoGallery

@MainActor
final class PhotoViewModelTests: XCTestCase {

    // MARK: List View Model Tests
    func testListDeleteFailureKeepsVisibleRows() async throws {
        let persistence = PersistenceController(inMemory: true)
        let photos = try makePhotos(ids: [1, 2], persistence: persistence)
        let repository = MockPhotoRepository()
        repository.photos = photos
        repository.deletePhotoError = CoreDataError.notFound
        let viewModel = PhotoListViewModel(repository: repository)

        await viewModel.loadInitial()
        
        // Trigger swipe to delete
        viewModel.deletePhotos(at: IndexSet(integer: 0))
        
        XCTAssertTrue(viewModel.showDeleteConfirmation)
        XCTAssertEqual(viewModel.photoToDelete?.photoID, 1)
        
        // Execute the delete action from the alert
        viewModel.performDelete()

        XCTAssertEqual(viewModel.photos.map(\.photoID), [1, 2])
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testListDeleteSuccessRemovesRowsAfterRepositoryDelete() async throws {
        let persistence = PersistenceController(inMemory: true)
        let photos = try makePhotos(ids: [1, 2, 3], persistence: persistence)
        let repository = MockPhotoRepository()
        repository.photos = photos
        let viewModel = PhotoListViewModel(repository: repository)

        await viewModel.loadInitial()
        
        // Trigger swipe to delete
        viewModel.deletePhotos(at: IndexSet(integer: 1))
        
        XCTAssertTrue(viewModel.showDeleteConfirmation)
        XCTAssertEqual(viewModel.photoToDelete?.photoID, 2)
        
        // Execute the delete action from the alert
        viewModel.performDelete()

        XCTAssertEqual(repository.deletedPhotoIDs, [2])
        XCTAssertEqual(viewModel.photos.map(\.photoID), [1, 3])
    }

    func testListUpdatesVisibleRowTitleWithoutReloading() async throws {
        let persistence = PersistenceController(inMemory: true)
        let photos = try makePhotos(ids: [1, 2], persistence: persistence)
        let repository = MockPhotoRepository()
        repository.photos = photos
        let viewModel = PhotoListViewModel(repository: repository)

        await viewModel.loadInitial()
        viewModel.updatePhotoTitle(photoID: 2, title: "Updated title")

        XCTAssertEqual(viewModel.photos.map(\.title), ["Photo 1", "Updated title"])
    }

    // MARK: Detail View Model Tests
    func testDetailSaveTrimsTitleAndClearsChangeState() throws {
        let persistence = PersistenceController(inMemory: true)
        let photo = try makePhotos(ids: [10], persistence: persistence).first!
        let repository = MockPhotoRepository()
        let viewModel = PhotoDetailViewModel(photo: photo, repository: repository)

        viewModel.title = "  Updated title  "
        let didSave = viewModel.save()

        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.updatedTitles[10], "Updated title")
        XCTAssertEqual(viewModel.title, "Updated title")
        XCTAssertFalse(viewModel.canSave)
    }

    func testDetailDeleteReportsRepositoryFailure() throws {
        let persistence = PersistenceController(inMemory: true)
        let photo = try makePhotos(ids: [10], persistence: persistence).first!
        let repository = MockPhotoRepository()
        repository.deletePhotoError = CoreDataError.notFound
        let viewModel = PhotoDetailViewModel(photo: photo, repository: repository)

        let didDelete = viewModel.delete()

        XCTAssertFalse(didDelete)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: Helpers
    private func makePhotos(ids: [Int64], persistence: PersistenceController) throws -> [Photo] {
        let context = persistence.viewContext
        let photos = ids.map { id in
            let photo = Photo(context: context)
            photo.id = id
            photo.albumId = 1
            photo.title = "Photo \(id)"
            photo.url = "https://example.com/\(id).png"
            photo.thumbnailUrl = "https://example.com/\(id)-thumb.png"
            return photo
        }
        try context.save()
        return photos
    }
}

// MARK: - Mock Repository
@MainActor
private final class MockPhotoRepository: PhotoRepositoryProtocol {
    var photos: [Photo] = []
    var updatedTitles: [Int64: String] = [:]
    var deletedPhotoIDs: [Int64] = []
    var deletedBatchIDs: [Int64] = []
    var deletePhotoError: Error?
    var deletePhotosError: Error?

    func photoCount() throws -> Int {
        photos.count
    }

    func fetchPhotos(limit: Int, offset: Int) throws -> [Photo] {
        Array(photos.dropFirst(offset).prefix(limit))
    }

    func fetchPhoto(objectID: NSManagedObjectID) throws -> Photo {
        guard let photo = photos.first(where: { $0.objectID == objectID }) else {
            throw CoreDataError.notFound
        }
        return photo
    }

    func fetchNextPageFromAPI() async throws -> Int {
        0
    }

    func updateTitle(id: Int64, newTitle: String) throws {
        updatedTitles[id] = newTitle
    }

    func deletePhoto(id: Int64) throws {
        if let deletePhotoError {
            throw deletePhotoError
        }
        deletedPhotoIDs.append(id)
        photos.removeAll { $0.id == id }
    }

    func deletePhotos(ids: [Int64]) throws {
        if let deletePhotosError {
            throw deletePhotosError
        }
        deletedBatchIDs = ids
        let idSet = Set(ids)
        photos.removeAll { idSet.contains($0.id) }
    }
}
