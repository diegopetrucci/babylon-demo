import Foundation

struct Photo {
    let id: Int
    let title: String
    let url: URL
    let thumbnailURL: URL
}

extension Photo: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case thumbnailURL = "thumbnailUrl"
    }
}
