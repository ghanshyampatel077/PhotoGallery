import Foundation

@MainActor
final class RemotePhotoListViewModel: ObservableObject {
    @Published private(set) var photos: [PhotoDTO] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: PhotoAPIServiceProtocol

    init(service: PhotoAPIServiceProtocol = PhotoAPIService()) {
        self.service = service
    }

    func loadPhotos() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            photos = try await service.fetchPhotos(page: 1, limit: 30)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
