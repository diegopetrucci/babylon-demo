import SwiftUI
import Combine

extension ListView {
    struct Element: Identifiable {
        let id: Int
        let title: String
        let thumbnailURL: URL // TODO remove
        let thumbnail: Thumbnail?
        let isFavourite: Bool
        let albumID: Int
    }
    
    struct Thumbnail {
        let id: Int
        let image: UIImage?
        let size: CGSize?
    }
}

extension ListView.Thumbnail: Equatable {}

extension ListView.Thumbnail: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#if DEBUG
extension ListView.Element {
    static func fixture(isFavourite: Bool = false) -> ListView.Element {
        .init(
            id: 47,
            title: "et soluta est",
            thumbnailURL: .fixture(),
            thumbnail: .init(
                id: 2,
                image: .fixture(),
                size: CGSize(width: 150, height: 150)
            ),
            isFavourite: isFavourite, albumID: 1
        )
    }
}
#endif

#if DEBUG
extension ListView.Thumbnail {
    static func fixture() -> ListView.Thumbnail {
        .init(
            id: 2,
            image: .fixture(),
            size: .fixture()
        )
    }
}
#endif
