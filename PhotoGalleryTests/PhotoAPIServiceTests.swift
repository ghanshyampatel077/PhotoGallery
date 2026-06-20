import XCTest
@testable import PhotoGallery

@MainActor
final class PhotoAPIServiceTests: XCTestCase {
    
    // MARK: Teardown
    override func tearDown() {
        MockURLProtocol.responseProvider = nil
        super.tearDown()
    }

    // MARK: Success Tests
    func testFetchPhotosDecodesSuccessfulResponse() async throws {
        MockURLProtocol.responseProvider = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = Dictionary(
                uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
            )
            XCTAssertEqual(queryItems[AppConstants.API.pageQueryName], "1")
            XCTAssertEqual(queryItems[AppConstants.API.limitQueryName], "30")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            [
              {
                "albumId": 1,
                "id": 10,
                "title": "A photo",
                "url": "https://example.com/photo.png",
                "thumbnailUrl": "https://example.com/thumb.png"
              }
            ]
            """.data(using: .utf8)!

            return (response, data)
        }

        let photos = try await makeService().fetchPhotos(page: 1, limit: 30)

        XCTAssertEqual(photos.count, 1)
        XCTAssertEqual(photos.first?.id, 10)
        XCTAssertEqual(photos.first?.title, "A photo")
    }

    // MARK: Error Tests
    func testFetchPhotosThrowsServerErrorForNonSuccessfulStatus() async throws {
        MockURLProtocol.responseProvider = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await makeService().fetchPhotos(page: 1, limit: 30)
            XCTFail("Expected server error")
        } catch PhotoAPIError.server(let statusCode) {
            XCTAssertEqual(statusCode, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchPhotosThrowsEmptyResponseForEmptySuccessfulBody() async throws {
        MockURLProtocol.responseProvider = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await makeService().fetchPhotos(page: 1, limit: 30)
            XCTFail("Expected empty response error")
        } catch PhotoAPIError.emptyResponse {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: Helpers
    private func makeService() -> PhotoAPIService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return PhotoAPIService(session: URLSession(configuration: configuration))
    }
}

// MARK: - Mock URL Protocol
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseProvider: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let responseProvider = Self.responseProvider else {
            client?.urlProtocol(self, didFailWithError: PhotoAPIError.invalidResponse)
            return
        }

        do {
            let (response, data) = try responseProvider(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
