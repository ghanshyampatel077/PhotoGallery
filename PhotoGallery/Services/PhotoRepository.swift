import CoreData
import Foundation

// MARK: - Repository Contract
@MainActor
protocol PhotoRepositoryProtocol {
    func photoCount() throws -> Int
    func fetchPhotos(limit: Int, offset: Int) throws -> [Photo]
    func fetchPhoto(objectID: NSManagedObjectID) throws -> Photo
    func fetchNextPageFromAPI() async throws -> Int
    func updateTitle(id: Int64, newTitle: String) throws
    func deletePhoto(id: Int64) throws
    func deletePhotos(ids: [Int64]) throws
}

// MARK: - Photo Repository
@MainActor
final class PhotoRepository: PhotoRepositoryProtocol {
    
    // MARK: Constants
    static let pageSize = 30
    private static let lastAPIPageKey = AppConstants.Persistence.lastFetchedAPIPageKey

    // MARK: Dependencies
    private let persistence: PersistenceController
    private let apiService: PhotoAPIServiceProtocol
    private let userDefaults: UserDefaults

    // MARK: Initialization
    init(
        persistence: PersistenceController? = nil,
        apiService: PhotoAPIServiceProtocol? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.persistence = persistence ?? .shared
        self.apiService = apiService ?? PhotoAPIService()
        self.userDefaults = userDefaults
    }

    // MARK: Read Operations
    func photoCount() throws -> Int {
        let request = Photo.fetchRequest()
        do {
            return try persistence.viewContext.count(for: request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    func fetchPhotos(limit: Int, offset: Int) throws -> [Photo] {
        let request = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.id, ascending: true)]
        request.fetchLimit = limit
        request.fetchOffset = offset

        do {
            return try persistence.viewContext.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    func fetchPhoto(objectID: NSManagedObjectID) throws -> Photo {
        do {
            guard let photo = try persistence.viewContext.existingObject(with: objectID) as? Photo else {
                throw CoreDataError.notFound
            }
            return photo
        } catch let error as CoreDataError {
            throw error
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    // MARK: Sync Operations
    func fetchNextPageFromAPI() async throws -> Int {
        let count = try photoCount()
        let page = nextAPIPage(localCount: count)
        let dtos = try await apiService.fetchPhotos(page: page, limit: Self.pageSize)
        guard !dtos.isEmpty else { return 0 }

        try await upsertPhotos(dtos)
        lastFetchedAPIPage = page
        return dtos.count
    }

    // MARK: Write Operations
    func updateTitle(id: Int64, newTitle: String) throws {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let context = persistence.viewContext
        guard let photo = try fetchPhoto(id: id, in: context) else {
            throw CoreDataError.notFound
        }

        photo.title = trimmedTitle
        try persistence.save(context: context)
    }

    func deletePhoto(id: Int64) throws {
        let context = persistence.viewContext
        guard let photo = try fetchPhoto(id: id, in: context) else {
            throw CoreDataError.notFound
        }

        context.delete(photo)
        try persistence.save(context: context)
    }

    func deletePhotos(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }

        let context = persistence.viewContext
        let photos = try fetchPhotos(ids: ids, in: context)
        guard photos.count == Set(ids).count else {
            throw CoreDataError.notFound
        }

        photos.forEach(context.delete)
        try persistence.save(context: context)
    }

    // MARK: Pagination State
    private var scopedLastAPIPageKey: String {
        "\(Self.lastAPIPageKey).\(persistence.storeIdentifier)"
    }

    private var lastFetchedAPIPage: Int {
        get { userDefaults.integer(forKey: scopedLastAPIPageKey) }
        set { userDefaults.set(newValue, forKey: scopedLastAPIPageKey) }
    }

    private func nextAPIPage(localCount: Int) -> Int {
        let inferredCompletedPages = localCount / Self.pageSize
        return max(lastFetchedAPIPage, inferredCompletedPages) + 1
    }

    // MARK: Core Data Helpers
    private func fetchPhoto(id: Int64, in context: NSManagedObjectContext) throws -> Photo? {
        let request = Photo.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: AppConstants.CoreData.photoIDEqualsPredicate, id)

        do {
            return try context.fetch(request).first
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    private func fetchPhotos(ids: [Int64], in context: NSManagedObjectContext) throws -> [Photo] {
        let request = Photo.fetchRequest()
        request.predicate = NSPredicate(format: AppConstants.CoreData.photoIDInPredicate, ids)

        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    private func upsertPhotos(_ dtos: [PhotoDTO]) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let dtoIDs = dtos.map { Int64($0.id) }
            let request = Photo.fetchRequest()
            request.predicate = NSPredicate(format: AppConstants.CoreData.photoIDInPredicate, dtoIDs)

            let existingPhotos = try context.fetch(request)
            var photosByID = Dictionary(uniqueKeysWithValues: existingPhotos.map { ($0.id, $0) })

            for dto in dtos {
                let dtoID = Int64(dto.id)
                let existingPhoto = photosByID[dtoID]
                let photo = existingPhoto ?? Photo(context: context)
                photo.id = Int64(dto.id)
                photo.albumId = Int64(dto.albumId)
                photo.url = Self.displayImageURL(
                    from: dto.url,
                    fallbackSize: AppConstants.ImageURL.displayImageSize,
                    photoID: dto.id
                )
                photo.thumbnailUrl = Self.displayImageURL(
                    from: dto.thumbnailUrl,
                    fallbackSize: AppConstants.ImageURL.thumbnailImageSize,
                    photoID: dto.id
                )

                if existingPhoto == nil || photo.title?.isEmpty != false {
                    photo.title = dto.title
                }

                photosByID[dtoID] = photo
            }

            try self.persistence.save(context: context)
        }
    }

    nonisolated private static func displayImageURL(from apiURL: String?, fallbackSize: Int, photoID: Int) -> String {
        guard
            let apiURL,
            let components = URLComponents(string: apiURL),
            components.host == AppConstants.ImageURL.placeholderHost
        else {
            return apiURL ?? AppConstants.ImageURL.emptyURL
        }

        let pathParts = components.path.split(separator: AppConstants.ImageURL.pathSeparator)
        let rawSize = pathParts.first.map(String.init) ?? AppConstants.ImageURL.emptyURL
        let size = Int(rawSize) ?? fallbackSize
        let color = pathParts.dropFirst().first.map(String.init) ?? AppConstants.ImageURL.defaultColor

        return AppConstants.ImageURL.replacementURL(size: size, color: color, photoID: photoID)
    }
}
