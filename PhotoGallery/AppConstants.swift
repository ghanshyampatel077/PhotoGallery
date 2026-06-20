import Foundation

nonisolated enum AppConstants {
    enum Animation {
        static let splashMinimumDurationNanoseconds: UInt64 = 1_100_000_000
        static let splashDismissDuration = 0.34
    }

    enum API {
        static let photosBaseURL = "https://jsonplaceholder.typicode.com/photos"
        static let pageQueryName = "_page"
        static let limitQueryName = "_limit"
    }

    enum Assets {
        static let photoPlaceholder = "photo-placeholder"
    }

    enum Accessibility {
        static let fullScreenPhoto = "Full screen photo"
        static let closePhoto = "Close photo"
    }

    enum CoreData {
        static let modelName = "PhotoGallery"
        static let inMemoryStorePath = "/dev/null"
        static let photoIDEqualsPredicate = "id == %lld"
        static let photoIDInPredicate = "id IN %@"
    }

    enum Errors {
        static let invalidPhotoServiceURL = "The photo service URL is invalid."
        static let emptyPhotoServiceResponse = "No photos were returned from the server."
        static let invalidPhotoServiceResponse = "The photo service returned an invalid response."
        static let photoNotFound = "Photo not found."
        static let genericFailure = "Something went wrong."

        static func photoServiceStatusCode(_ statusCode: Int) -> String {
            "The photo service returned status code \(statusCode)."
        }

        static func network(_ message: String) -> String {
            "Network error: \(message)"
        }

        static func decoding(_ message: String) -> String {
            "Failed to read photo data: \(message)"
        }

        static func coreDataLoad(_ message: String) -> String {
            "Failed to load saved photos: \(message)"
        }

        static func coreDataSave(_ message: String) -> String {
            "Failed to save photos: \(message)"
        }

        static func coreDataFetch(_ message: String) -> String {
            "Failed to fetch photos: \(message)"
        }

        static func coreDataDelete(_ message: String) -> String {
            "Failed to delete photo: \(message)"
        }

        static func previewSeed(_ message: String) -> String {
            "Preview seed failed: \(message)"
        }

        static func coreDataStoreLoad(_ message: String) -> String {
            "Core Data load failed: \(message)"
        }
    }

    enum ImageURL {
        static let displayImageSize = 600
        static let thumbnailImageSize = 150
        static let placeholderHost = "via.placeholder.com"
        static let replacementHost = "placehold.co"
        static let defaultColor = "cccccc"
        static let emptyURL = ""
        static let pathSeparator: Character = "/"
        static let textColor = "ffffff"
        static let pngPathComponent = "png"
        static let textQueryName = "text"

        static func replacementURL(size: Int, color: String, photoID: Int) -> String {
            "https://\(replacementHost)/\(size)x\(size)/\(color)/\(textColor)/\(pngPathComponent)?\(textQueryName)=\(photoID)"
        }
    }

    enum Persistence {
        static let lastFetchedAPIPageKey = "lastFetchedAPIPage"
    }

    enum PreviewData {
        static let albumID: Int64 = 1
        static let imageURL = "https://via.placeholder.com/600/92c952"
        static let thumbnailURL = "https://via.placeholder.com/150/92c952"
        static let zoomImageURL = "https://placehold.co/600x600/92c952/ffffff/png?text=1"

        static func title(index: Int) -> String {
            "Sample photo \(index)"
        }
    }

    enum SystemImage {
        static let close = "xmark"
        static let chevronRight = "chevron.right"
        static let photo = "photo"
        static let emptyPhotos = "photo.on.rectangle.angled"
        static let trash = "trash"
    }

    enum UI {
        static let appName = "Photo Gallery"
        static let cancel = "Cancel"
        static let delete = "Delete"
        static let deletePhoto = "Delete Photo"
        static let deletePhotoQuestion = "Delete Photo?"
        static let deletePhotoMessage = "This photo will be permanently removed."
        static let done = "Done"
        static let emptyPhotosMessage = "Photos will appear here once they are loaded."
        static let emptyPhotosTitle = "No Photos Yet"
        static let error = "Error"
        static let loadingPhotos = "Loading photos..."
        static let ok = "OK"
        static let photoDetailsTitle = "Photo Details"
        static let photosTitle = "Photos"
        static let retry = "Retry"
        static let save = "Save"
        static let splashSubtitle = "Moments, neatly organized"
        static let titleLabel = "Title"
        static let titlePlaceholder = "Enter title"

        static func albumNumber(_ albumID: Int64) -> String {
            "Album \(albumID)"
        }

        static func photoNumber(_ photoID: Int64) -> String {
            "Photo #\(photoID)"
        }
    }
}
