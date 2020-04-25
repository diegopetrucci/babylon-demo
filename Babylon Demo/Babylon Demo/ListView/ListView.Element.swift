import SwiftUI
import Combine

extension ListView {
    struct Element: Identifiable {
        let id: Int
        let title: String
        var thumbnail: Thumbnail?
        var isFavourite: Bool
        let albumID: Int
    }
    
    struct Thumbnail {
        var image: UIImage
        let size: CGSize
    }
}

extension ListView.Element: With {}

#if DEBUG
extension ListView.Element {
    static func fixture(isFavourite: Bool = false) -> ListView.Element {
        .init(
            id: 47,
            title: "et soluta est",
            thumbnail: .init(
                image: UIImage(named: "thumbnail_mock")!,
                size: CGSize(width: 150, height: 150)
            ),
            isFavourite: isFavourite, albumID: 1
        )
    }
}
#endif
