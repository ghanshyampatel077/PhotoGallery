import XCTest
@testable import PhotoGallery

@MainActor
final class PhotoRepositoryTests: XCTestCase {
    
    // MARK: CRUD Tests
    func testFetchUpdateAndDeletePhoto() async throws {
        let repository = makeRepository(
            apiService: MockPhotoAPIService(
                pages: [
                    1: [
                        PhotoDTO(
                            albumId: 1,
                            id: 101,
                            title: "Original title",
                            url: "https://via.placeholder.com/600/92c952",
                            thumbnailUrl: "https://via.placeholder.com/150/92c952"
                        )
                    ]
                ]
            )
        )

        let fetchedCount = try await repository.fetchNextPageFromAPI()
        XCTAssertEqual(fetchedCount, 1)
        XCTAssertEqual(try repository.photoCount(), 1)

        var photos = try repository.fetchPhotos(limit: 30, offset: 0)
        XCTAssertEqual(photos.first?.title, "Original title")
        XCTAssertEqual(photos.first?.url, "https://placehold.co/600x600/92c952/ffffff/png?text=101")

        try repository.updateTitle(id: 101, newTitle: "Updated title")
        photos = try repository.fetchPhotos(limit: 30, offset: 0)
        XCTAssertEqual(photos.first?.title, "Updated title")

        try repository.deletePhoto(id: 101)
        XCTAssertEqual(try repository.photoCount(), 0)
    }

    // MARK: Duplicate Handling Tests
    func testUpsertPreventsDuplicatePhotoIDs() async throws {
        let repository = makeRepository(
            apiService: MockPhotoAPIService(
                pages: [
                    1: [
                        PhotoDTO(
                            albumId: 1,
                            id: 12,
                            title: "First title",
                            url: "https://via.placeholder.com/600/111111",
                            thumbnailUrl: "https://via.placeholder.com/150/111111"
                        ),
                        PhotoDTO(
                            albumId: 2,
                            id: 12,
                            title: "Duplicate title",
                            url: "https://via.placeholder.com/600/222222",
                            thumbnailUrl: "https://via.placeholder.com/150/222222"
                        )
                    ]
                ]
            )
        )

        _ = try await repository.fetchNextPageFromAPI()

        let photos = try repository.fetchPhotos(limit: 30, offset: 0)
        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(photos.first?.id, 12)
    }

    // MARK: Pagination Tests
    func testFetchNextPageAdvancesPagination() async throws {
        let apiService = MockPhotoAPIService(
            pages: [
                1: makePage(startingID: 1, count: PhotoRepository.pageSize),
                2: makePage(startingID: 31, count: PhotoRepository.pageSize)
            ]
        )
        let repository = makeRepository(apiService: apiService)

        let firstPageCount = try await repository.fetchNextPageFromAPI()
        let secondPageCount = try await repository.fetchNextPageFromAPI()
        XCTAssertEqual(firstPageCount, PhotoRepository.pageSize)
        XCTAssertEqual(secondPageCount, PhotoRepository.pageSize)

        let photos = try repository.fetchPhotos(limit: 100, offset: 0)
        XCTAssertEqual(photos.count, PhotoRepository.pageSize * 2)
        XCTAssertEqual(photos.first?.id, 1)
        XCTAssertEqual(photos.last?.id, 60)
        XCTAssertEqual(apiService.requestedPages, [1, 2])
    }

    func testFetchNextPageContinuesAfterAllLocalRowsAreDeleted() async throws {
        let apiService = MockPhotoAPIService(
            pages: [
                1: makePage(startingID: 1, count: PhotoRepository.pageSize),
                2: makePage(startingID: 31, count: PhotoRepository.pageSize)
            ]
        )
        let repository = makeRepository(apiService: apiService)

        _ = try await repository.fetchNextPageFromAPI()
        let firstPageIDs = try repository.fetchPhotos(limit: PhotoRepository.pageSize, offset: 0).map(\.id)
        try repository.deletePhotos(ids: firstPageIDs)

        _ = try await repository.fetchNextPageFromAPI()

        let photos = try repository.fetchPhotos(limit: PhotoRepository.pageSize, offset: 0)
        XCTAssertEqual(photos.first?.id, 31)
        XCTAssertEqual(apiService.requestedPages, [1, 2])
    }

    func testBatchDeleteIsAtomicWhenAnyPhotoIsMissing() async throws {
        let repository = makeRepository(
            apiService: MockPhotoAPIService(
                pages: [
                    1: [
                        PhotoDTO(
                            albumId: 1,
                            id: 101,
                            title: "Keep me",
                            url: "https://via.placeholder.com/600/92c952",
                            thumbnailUrl: "https://via.placeholder.com/150/92c952"
                        )
                    ]
                ]
            )
        )

        _ = try await repository.fetchNextPageFromAPI()

        XCTAssertThrowsError(try repository.deletePhotos(ids: [101, 999]))
        XCTAssertEqual(try repository.photoCount(), 1)
        XCTAssertEqual(try repository.fetchPhotos(limit: 30, offset: 0).first?.id, 101)
    }

    // MARK: Helpers
    private func makeRepository(apiService: MockPhotoAPIService) -> PhotoRepository {
        let suiteName = "PhotoGalleryTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        return PhotoRepository(
            persistence: PersistenceController(inMemory: true),
            apiService: apiService,
            userDefaults: userDefaults
        )
    }

    private func makePage(startingID: Int, count: Int) -> [PhotoDTO] {
        (startingID..<(startingID + count)).map { id in
            PhotoDTO(
                albumId: 1,
                id: id,
                title: "Photo \(id)",
                url: "https://via.placeholder.com/600/cccccc",
                thumbnailUrl: "https://via.placeholder.com/150/cccccc"
            )
        }
    }
}

// MARK: - Mock API Service
final class MockPhotoAPIService: PhotoAPIServiceProtocol {
    private let pages: [Int: [PhotoDTO]]
    private(set) var requestedPages: [Int] = []

    init(pages: [Int: [PhotoDTO]]) {
        self.pages = pages
    }

    func fetchPhotos(page: Int, limit: Int) async throws -> [PhotoDTO] {
        requestedPages.append(page)
        return Array((pages[page] ?? []).prefix(limit))
    }
}
