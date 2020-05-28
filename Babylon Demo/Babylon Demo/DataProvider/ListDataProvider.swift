import Combine
import Disk

protocol ListDataProviderProtocol {
    func fetchMetadata() -> AnyPublisher<[ListView.Element], ListDataProviderError>
    func persist(elements: [ListView.Element]) -> AnyPublisher<Void, Never>
}

struct ListDataProvider: ListDataProviderProtocol {
    private let api: API
    private let persister: PersisterProtocol

    init(api: API, persister: PersisterProtocol) {
        self.api = api
        self.persister = persister
    }

    func fetchMetadata() -> AnyPublisher<[ListView.Element], ListDataProviderError> {
        persister.fetch(type: [ListView.Element].self, path: Self.elementsPath)
            .catch { _ in
                // The API has no pagination, so given that this data
                // is loaded extremely fast I've decided to download it
                // in one go, decode it, and map it to `ListView.Element`.
                // Having a paginated API would definitely be better.
                return self.api.photos()
                    .map { photos in photos.map(self.element(from:)) }
                    .map { $0.sorted(by: Self.isSortedByFavourites) }
                    .eraseToAnyPublisher()
        }
        .mapError { _ in .error }
        .eraseToAnyPublisher()
    }

    func persist(elements: [ListView.Element]) -> AnyPublisher<Void, Never> {
        persister.persist(t: elements, path: Self.elementsPath)
            .map { _ in () } // We just care about the completion of the publisher. Similar to `.then()`
            .replaceError(with: ()) // TODO handle error
            .eraseToAnyPublisher()
    }
}

extension ListDataProvider {
    private func element(from photo: Photo) -> ListView.Element {
        ListView.Element(
            id: photo.id,
            title: photo.title,
            photoURL: photo.url,
            thumbnailURL: photo.thumbnailURL,
            isFavourite: false,
            albumID: photo.albumID
        )
    }
}

extension ListDataProvider {
    static func isSortedByFavourites(firstElement: ListView.Element, secondElement: ListView.Element) -> Bool {
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

extension ListDataProvider {
    private static var elementsPath = "/ListView/elements"
}

enum ListDataProviderError: Error {
    case error
}

#if DEBUG
struct ListDataProviderFixture: ListDataProviderProtocol {
    func fetchMetadata() -> AnyPublisher<[ListView.Element], ListDataProviderError> {
        Just([
            ListView.Element.fixture(isFavourite: true),
            ListView.Element.fixture(),
            ListView.Element.fixture(),
            ListView.Element.fixture()
        ])
            .setFailureType(to: ListDataProviderError.self)
            .eraseToAnyPublisher()
    }

    func persist(elements: [ListView.Element]) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}
#endif
