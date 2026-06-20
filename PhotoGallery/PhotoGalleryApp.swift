internal import CoreData
import SwiftUI

@main
struct PhotoGalleryApp: App {
    
    // MARK: Dependencies
    let persistenceController: PersistenceController
    private let photoRepository: PhotoRepositoryProtocol

    // MARK: Initialization
    init() {
        let persistenceController = PersistenceController.shared
        self.persistenceController = persistenceController
        self.photoRepository = PhotoRepository(persistence: persistenceController)
    }

    // MARK: Scene
    var body: some Scene {
        WindowGroup {
            if let loadError = persistenceController.loadError {
                EmptyStateView(
                    title: AppConstants.UI.error,
                    message: loadError.localizedDescription
                )
            } else {
                RootView(repository: photoRepository)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
