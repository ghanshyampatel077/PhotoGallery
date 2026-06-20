import Foundation

// MARK: - API Photo Model
struct PhotoDTO: Decodable, Identifiable, Sendable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}
