import Foundation

// MARK: - API Errors
enum PhotoAPIError: LocalizedError {
    case invalidURL
    case emptyResponse
    case invalidResponse
    case server(statusCode: Int)
    case network(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return AppConstants.Errors.invalidPhotoServiceURL
        case .emptyResponse:
            return AppConstants.Errors.emptyPhotoServiceResponse
        case .invalidResponse:
            return AppConstants.Errors.invalidPhotoServiceResponse
        case .server(let statusCode):
            return AppConstants.Errors.photoServiceStatusCode(statusCode)
        case .network(let error):
            return AppConstants.Errors.network(error.localizedDescription)
        case .decoding(let error):
            return AppConstants.Errors.decoding(error.localizedDescription)
        }
    }
}

// MARK: - API Service Contract
nonisolated protocol PhotoAPIServiceProtocol {
    func fetchPhotos(page: Int, limit: Int) async throws -> [PhotoDTO]
}

// MARK: - Photo API Service
nonisolated struct PhotoAPIService: PhotoAPIServiceProtocol {
    
    // MARK: Dependencies
    private static let baseURL = URL(string: AppConstants.API.photosBaseURL)!
    private let session: URLSession

    // MARK: Initialization
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Fetching
    func fetchPhotos(page: Int, limit: Int) async throws -> [PhotoDTO] {
        guard page >= 1, limit >= 1 else {
            throw PhotoAPIError.invalidURL
        }

        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: AppConstants.API.pageQueryName, value: String(page)),
            URLQueryItem(name: AppConstants.API.limitQueryName, value: String(limit))
        ]

        guard let url = components?.url else {
            throw PhotoAPIError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw PhotoAPIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PhotoAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw PhotoAPIError.server(statusCode: httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw PhotoAPIError.emptyResponse
        }

        do {
            return try JSONDecoder().decode([PhotoDTO].self, from: data)
        } catch {
            throw PhotoAPIError.decoding(error)
        }
    }
}
