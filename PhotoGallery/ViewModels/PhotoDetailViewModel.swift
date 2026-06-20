import CoreData
import Foundation
import Observation

@MainActor
@Observable
final class PhotoDetailViewModel {
    
    // MARK: State
    let photoID: Int64
    let albumID: Int64
    let imageURLString: String
    let thumbnailURLString: String
    var title: String
    var errorMessage: String?
    var showDeleteConfirmation = false

    private let repository: PhotoRepositoryProtocol
    private var originalTitle: String

    // MARK: Derived State
    var hasChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != originalTitle
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasChanges
    }

    // MARK: Initialization
    init(
        photo: Photo,
        repository: PhotoRepositoryProtocol,
        initialTitle: String? = nil,
        initialThumbnailURLString: String? = nil
    ) {
        let displayTitle = initialTitle ?? photo.title ?? ""

        self.photoID = photo.id
        self.albumID = photo.albumId
        self.imageURLString = photo.url ?? AppConstants.ImageURL.emptyURL
        self.thumbnailURLString = initialThumbnailURLString ?? photo.thumbnailUrl ?? AppConstants.ImageURL.emptyURL
        self.title = displayTitle
        self.originalTitle = displayTitle
        self.repository = repository
    }

    // MARK: Actions
    func save() -> Bool {
        do {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            try repository.updateTitle(id: photoID, newTitle: trimmedTitle)
            title = trimmedTitle
            originalTitle = trimmedTitle
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete() -> Bool {
        do {
            try repository.deletePhoto(id: photoID)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
