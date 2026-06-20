internal import CoreData

// MARK: - Core Data Errors
enum CoreDataError: LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return AppConstants.Errors.coreDataLoad(error.localizedDescription)
        case .saveFailed(let error):
            return AppConstants.Errors.coreDataSave(error.localizedDescription)
        case .fetchFailed(let error):
            return AppConstants.Errors.coreDataFetch(error.localizedDescription)
        case .deleteFailed(let error):
            return AppConstants.Errors.coreDataDelete(error.localizedDescription)
        case .notFound:
            return AppConstants.Errors.photoNotFound
        }
    }
}

// MARK: - Persistence Controller
struct PersistenceController {
    
    // MARK: Shared Stores
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for index in 1...5 {
            let photo = Photo(context: viewContext)
            photo.id = Int64(index)
            photo.albumId = AppConstants.PreviewData.albumID
            photo.title = AppConstants.PreviewData.title(index: index)
            photo.url = AppConstants.PreviewData.imageURL
            photo.thumbnailUrl = AppConstants.PreviewData.thumbnailURL
        }
        do {
            try viewContext.save()
        } catch {
            assertionFailure(AppConstants.Errors.previewSeed(error.localizedDescription))
        }
        return result
    }()

    let container: NSPersistentContainer
    let storeIdentifier: String
    let loadError: Error?

    // MARK: Initialization
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: AppConstants.CoreData.modelName)
        storeIdentifier = inMemory ? UUID().uuidString : AppConstants.CoreData.modelName
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: AppConstants.CoreData.inMemoryStorePath)
        }

        var capturedLoadError: Error?
        container.loadPersistentStores { _, error in
            if let error {
                capturedLoadError = CoreDataError.loadFailed(error)
            }
        }
        loadError = capturedLoadError

        if let loadError {
            assertionFailure(AppConstants.Errors.coreDataStoreLoad(loadError.localizedDescription))
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: Contexts
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: Saving
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw CoreDataError.saveFailed(error)
        }
    }
}
