internal import CoreData
import Foundation

struct PhotoRowModel: Identifiable, Equatable, Hashable {
    let objectID: NSManagedObjectID
    let photoID: Int64
    let albumID: Int64
    let title: String
    let thumbnailURLString: String

    var id: NSManagedObjectID {
        objectID
    }

    init(photo: Photo) {
        objectID = photo.objectID
        photoID = photo.id
        albumID = photo.albumId
        title = photo.title ?? AppConstants.ImageURL.emptyURL
        thumbnailURLString = photo.thumbnailUrl ?? AppConstants.ImageURL.emptyURL
    }

    private init(
        objectID: NSManagedObjectID,
        photoID: Int64,
        albumID: Int64,
        title: String,
        thumbnailURLString: String
    ) {
        self.objectID = objectID
        self.photoID = photoID
        self.albumID = albumID
        self.title = title
        self.thumbnailURLString = thumbnailURLString
    }

    func updatingTitle(_ title: String) -> PhotoRowModel {
        PhotoRowModel(
            objectID: objectID,
            photoID: photoID,
            albumID: albumID,
            title: title,
            thumbnailURLString: thumbnailURLString
        )
    }
}
