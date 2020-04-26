import SwiftUI
import Combine

extension ListView {
    struct Element: Identifiable {
        let id: Int
        let title: String
        let thumbnail: Thumbnail?
        let photoURL: URL // TODO preferably this would not be exposed to the view
        let isFavourite: Bool
        let albumID: Int
    }
    
    struct Thumbnail {
        let id: Int
        let url: URL // TODO preferably this would not be exposed to the view
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
            thumbnail: .init(
                id: 47,
                url: URL(string: "http://google.com")!,
                image: UIImage(named: "thumbnail_mock")!,
                size: CGSize(width: 150, height: 150)
            ),
            photoURL: URL(string: "http://google.com")!,
            isFavourite: isFavourite, albumID: 1
        )
    }
}
#endif
