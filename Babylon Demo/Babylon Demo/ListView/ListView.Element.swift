import SwiftUI
import Combine

extension ListView {
    struct Element: Identifiable {
        let id: Int
        let title: String
        let photoURL: URL // TODO remove
        let thumbnailURL: URL // TODO remove
        let isFavourite: Bool
        let albumID: Int
    }
}

extension ListView.Element: Codable {}

#if DEBUG
extension ListView.Element {
    static func fixture(isFavourite: Bool = false) -> ListView.Element {
        .init(
            id: 47,
            title: "et soluta est",
            photoURL: .fixture(),
            thumbnailURL: .fixture(),
            isFavourite: isFavourite, albumID: 1
        )
    }
}
#endif
