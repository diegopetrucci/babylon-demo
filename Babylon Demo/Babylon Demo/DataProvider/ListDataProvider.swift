import Combine
import Disk

protocol ListDataProviderProtocol {
    func fetchMetadata() -> AnyPublisher<[ListView.Element], RemoteError>
    func persist(elements: [ListView.Element]) -> AnyPublisher<Void, Never>
}

struct ListDataProvider: ListDataProviderProtocol {
    private let api: API

    init(api: API) {
        self.api = api
    }

    func fetchMetadata() -> AnyPublisher<[ListView.Element], RemoteError> {
        if let elements = try? Disk.retrieve(Self.elementsPath, from: .caches, as: [ListView.Element].self) {
            print("elements were already present, fetching from disk")
            return Just(elements)
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        }

        print("elements not present, fetching from network")

        // The API has no pagination, so given that this data
        // is loaded extremely fast I've decided to download it
        // in one go, decode it, and map it to `ListView.Element`.
        // Having a paginated API would definitely be better.
        return api.photos()
            .map { photos in photos.map(self.element(from:)) }
            .map { $0.sorted(by: Self.isSortedByFavourites) }
            .eraseToAnyPublisher()
    }

    func persist(elements: [ListView.Element]) -> AnyPublisher<Void, Never> {
        if (try? Disk.retrieve(Self.elementsPath, from: .caches, as: [ListView.Element].self)) != nil {
            print("elements were already present, skipping persisting")
            return Just(()).eraseToAnyPublisher()
        }

        if (try? Disk.save(elements, to: .caches, as: Self.elementsPath)) != nil {
            print("Persisting elements")
            return Just(()).eraseToAnyPublisher()
        }

        print("elements failed to persist")
        return Just(()).eraseToAnyPublisher()
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

#if DEBUG
struct ListDataProviderFixture: ListDataProviderProtocol {
    func fetchMetadata() -> AnyPublisher<[ListView.Element], RemoteError> {
        Just([
            ListView.Element.fixture(isFavourite: true),
            ListView.Element.fixture(),
            ListView.Element.fixture(),
            ListView.Element.fixture()
        ])
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }

    func persist(elements: [ListView.Element]) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}
#endif
