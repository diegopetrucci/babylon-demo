import Foundation

struct Photo {
    let id: Int
    let title: String
    let url: URL
    let thumbnailURL: URL
    let albumID: Int
}

extension Photo: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case thumbnailURL = "thumbnailUrl"
        case albumID = "albumId"
    }
}
