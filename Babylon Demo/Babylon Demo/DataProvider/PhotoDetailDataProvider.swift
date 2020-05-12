import Combine
import Disk

protocol PhotoDetailDataProviderProtocol {
    func fetchAuthorAndNumberOfComments(albumID: Int, photoID: Int) -> AnyPublisher<(String, Int), RemoteError>
    func persist(author: String, numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never>
}

struct PhotoDetailDataProvider: PhotoDetailDataProviderProtocol {
    private let api: API

    init(api: API) {
        self.api = api
    }

    func fetchAuthorAndNumberOfComments(albumID: Int, photoID: Int) -> AnyPublisher<(String, Int), RemoteError> {
        // Note: here I'm simplifying it a bit, by making it required
        //       for both author _and_ number of comments to be present.
        //       I think it makes sense given that they relate to the same
        //       photo, but I can see why this logic should be 1) separate
        //       or, even better, prioritizing fetching the comments every
        //       time since they're likely to change.
        if
            let author = try? Disk.retrieve(
                Self.authorPath(for: photoID),
                from: .caches,
                as: String.self
            ),
            let numberofComments = try? Disk.retrieve(
                Self.numberOfCommentsPath(for: photoID),
                from: .caches,
                as: Int.self
            )
        {
            print("author and number of comments were already present, fetching from disk")
            return Just((author, numberofComments))
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        }

        print("author and number of comments not present, fetching from network")

        return Publishers.Zip(
            api.album(with: albumID)
                .flatMap { self.api.user(with: $0.userID) }
                .map { $0.name },
            api.comments(for: photoID)
                .map { $0.count }
        )
            .eraseToAnyPublisher()
    }

    func persist(author: String, numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never> {
        if
            (try? Disk.retrieve(Self.authorPath(for: photoID), from: .caches, as: String.self)) != nil,
            (try? Disk.retrieve(Self.numberOfCommentsPath(for: photoID), from: .caches, as: Int.self)) != nil
        {
            print("author and number of comments were already present, skipping persisting")
            return Just(()).eraseToAnyPublisher()
        }

        if
            (try? Disk.save(author, to: .caches, as: Self.authorPath(for: photoID))) != nil,
            (try? Disk.save(numberOfComments, to: .caches, as: Self.numberOfCommentsPath(for: photoID))) != nil
        {
            print("Persisting author and number of comments")
            return Just(()).eraseToAnyPublisher()
        }

        print("author and number of comments failed to persist")
        return Just(()).eraseToAnyPublisher()
    }
}

extension PhotoDetailDataProvider {
    private static func authorPath(for photoID: Int) -> String {
        "/Photo\(photoID)/author"
    }

    private static func numberOfCommentsPath(for photoID: Int) -> String {
        "/Photo\(photoID)/numberOfComments"
    }
}

#if DEBUG
struct PhotoDetailDataProviderFixture: PhotoDetailDataProviderProtocol {
    func fetchAuthorAndNumberOfComments(albumID: Int, photoID: Int) -> AnyPublisher<(String, Int), RemoteError> {
        Just(("Napoleone Bonaparte", 11))
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }

    func persist(author: String, numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}
#endif
