import Combine
import Disk

protocol PhotoDetailDataProviderProtocol {
    func fetchAuthorAndNumberOfComments(albumID: Int, photoID: Int) -> AnyPublisher<(String, Int), PhotoDataProviderError>
    func persist(author: String, numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never>
}

struct PhotoDetailDataProvider: PhotoDetailDataProviderProtocol {
    private let api: API
    private let persister: PersisterProtocol

    init(api: API, persister: PersisterProtocol) {
        self.api = api
        self.persister = persister
    }

    func fetchAuthorAndNumberOfComments(
        albumID: Int,
        photoID: Int
    ) -> AnyPublisher<(String, Int), PhotoDataProviderError> {
        // Note: here I'm simplifying it a bit, by making it required
        //       for both author _and_ number of comments to be present.
        //       I think it makes sense given that they relate to the same
        //       photo, but I can see why this logic should be 1) separate
        //       or, even better, prioritizing fetching the comments every
        //       time since they're likely to change.
        Publishers.Zip(
            persister.fetch(type: String.self, path: Self.authorPath(for: photoID)),
            persister.fetch(type: Int.self, path: Self.numberOfCommentsPath(for: photoID))
        )
            .catch { _ in
                // Fetching from the API when persitance
                // does not return values
                Publishers.Zip(
                    self.api.album(with: albumID)
                        .flatMap { self.api.user(with: $0.userID) }
                        .map { $0.name },
                    self.api.comments(for: photoID)
                        .map { $0.count }
                )
                .eraseToAnyPublisher()
            }
            .mapError { _ in PhotoDataProviderError.error }
            .eraseToAnyPublisher()
    }

    func persist(author: String, numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never> {
        Publishers.Zip(
            persister.persist(t: author, path: Self.authorPath(for: photoID)),
            persister.persist(t: numberOfComments, path: Self.numberOfCommentsPath(for: photoID))
        )
            .map { (authorResult, numberOfCommentsResult) in
                switch (authorResult, numberOfCommentsResult) {
                case (.dataAlreadyPresent, .dataAlreadyPresent),
                     (.persisted, .persisted):
                    return ()
                case (.dataAlreadyPresent, .persisted),
                     (.persisted, .dataAlreadyPresent):
                    return () // TODO return an error
                }
            }
        .replaceError(with: ()) // TODO
        .eraseToAnyPublisher()
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

enum PhotoDataProviderError: Error {
    case error
}

#if DEBUG
struct PhotoDetailDataProviderFixture: PhotoDetailDataProviderProtocol {
    func fetchAuthorAndNumberOfComments(
        albumID: Int,
        photoID: Int
    ) -> AnyPublisher<(String, Int), PhotoDataProviderError> {
        Just(("Napoleone Bonaparte", 11))
            .setFailureType(to: PhotoDataProviderError.self)
            .eraseToAnyPublisher()
    }

    func persist(author: String, numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}
#endif
