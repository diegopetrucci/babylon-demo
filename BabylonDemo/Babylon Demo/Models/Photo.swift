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

#if DEBUG
extension Photo {
    static func fixture(id: Int = 46, albumID: Int = 31) -> Self {
        .init(
            id: id,
            title: "et soluta est",
            url: .fixture(),
            thumbnailURL: .fixture(),
            albumID: albumID
        )
    }
}
#endif
