import Combine
import Foundation
import class SwiftUI.UIImage

final class ListViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let api: API
    private var thumbnailURLs: [URL] = []

    @Published private(set) var elements: [ListView.Element] = []
    @Published private(set) var thumbnails = Set<ListView.Thumbnail>()

    init(api: API = JSONPlaceholderAPI()) {
        self.api = api

        api.photos()
            .replaceError(with: [])
            .map { photos in
                photos.map { photo in
                    ListView.Element(
                        id: photo.id,
                        title: photo.title,
                        thumbnail: ListView.Thumbnail(
                            id: photo.id,
                            url: photo.thumbnailURL,
                            image: nil,
                            size: nil
                        ),
                        photoURL: photo.url,
                        isFavourite: false,
                        albumID: photo.albumID
                    )
                }
            }
            .map { $0.sorted(by: self.isSortedByFavourites) }
            .assign(to: \.elements, on: self)
            .store(in: &cancellables)
    }

    func onAppear() {
        // TODO
    }

    func onListCellAppear(_ index: Int) {
        let element = self.elements[index]

        // TODO it should not be an optional
        guard let url = self.elements[index].thumbnail?.url else { return }

        api.image(for: url)
            .sink { image in
                if let thumbnail = self.thumbnails.first(where: { $0.id == element.id }) {
                    self.thumbnails.remove(thumbnail)
                    self.thumbnails.insert(
                        ListView.Thumbnail(
                            id: element.id,
                            url: url,
                            image: image,
                            size: image?.size
                        )
                    )
                } else {
                    self.thumbnails.insert(
                        ListView.Thumbnail(
                            id: element.id,
                            url: url,
                            image: image,
                            size: image?.size
                        )
                    )
                }
        }
        .store(in: &cancellables)
    }
}

extension ListViewModel {
    func isSortedByFavourites(firstElement: ListView.Element, secondElement: ListView.Element) -> Bool {
        switch (firstElement.isFavourite, secondElement.isFavourite) {
        case (true, true), (false, false):
            return firstElement.id < secondElement.id
        case (true, false):
            return true
        case (false, true):
            return false
        }
    }
}

