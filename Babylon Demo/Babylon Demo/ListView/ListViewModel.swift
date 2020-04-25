import Combine
import Foundation
import class SwiftUI.UIImage

final class ListViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var elements: [ListView.Element] = []
    @Published private(set) var thumbnails: [ListView.Thumbnail?] = []

    init(api: API) {
        api.photos()
            .replaceError(with: [])
            .map { photos in
                photos.map { photo in
//                     TODO this is a mess
//                    let thumbnailPublisher: AnyPublisher<ListView.Thumbnail?, Never> = JSONPlaceholderAPI.thumbnail(for: photo.thumbnailURL)
//                        .map { image -> ListView.Thumbnail? in
//                            guard let image = image else { return nil }
//
//                            return ListView.Thumbnail(image: image, size: image.size)
//                        }
//                        .replaceError(with: nil)
//                        .eraseToAnyPublisher()
//                        .assign(to: \.thumbnails[0], on: self) // TODO lol
//                        .store(in: &self.cancellables)

                    return ListView.Element(
                        id: photo.id,
                        title: photo.title,
                        thumbnail: nil,
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

