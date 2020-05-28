import Combine
import Disk

typealias PhotoDetailDataProviderProtocol = AuthorDataProviderProtocol & NumberOfCommentsDataProviderProtocol

protocol AuthorDataProviderProtocol {
    func fetch(albumID: Int, photoID: Int) -> AnyPublisher<String, PhotoDataProviderError>
    func persist(author: String, photoID: Int) -> AnyPublisher<Void, Never>
}

protocol NumberOfCommentsDataProviderProtocol {
    func fetch(photoID: Int) -> AnyPublisher<Int, PhotoDataProviderError>
    func persist(numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never>
}

struct AuthorDataProvider: AuthorDataProviderProtocol {
    private let api: API
    private let persister: PersisterProtocol

    init(api: API, persister: PersisterProtocol) {
        self.api = api
        self.persister = persister
    }

    func fetch(albumID: Int, photoID: Int) -> AnyPublisher<String, PhotoDataProviderError> {
        persister.fetch(type: String.self, path: Self.authorPath(for: photoID))
            .catch { _ in
                // Fetching from the API when persitance
                // does not return values
                self.api.album(with: albumID)
                    .flatMap { self.api.user(with: $0.userID) }
                    .map { $0.name }
                    .eraseToAnyPublisher()
        }
        .mapError { _ in PhotoDataProviderError.error }
        .eraseToAnyPublisher()
    }

    func persist(author: String, photoID: Int) -> AnyPublisher<Void, Never> {
        persister.persist(t: author, path: Self.authorPath(for: photoID))
            .map { authorResult in
                switch authorResult {
                case .persisted:
                    return ()
                case .dataAlreadyPresent:
                    return () // TODO return an error
                }
            }
            .replaceError(with: ()) // TODO
            .eraseToAnyPublisher()
    }
}

extension AuthorDataProvider {
    private static func authorPath(for photoID: Int) -> String {
        "/Photo\(photoID)/author"
    }
}

struct NumberOfCommentsDataProvider: NumberOfCommentsDataProviderProtocol {
    private let api: API
    private let persister: PersisterProtocol

    init(api: API, persister: PersisterProtocol) {
        self.api = api
        self.persister = persister
    }

    func fetch(photoID: Int) -> AnyPublisher<Int, PhotoDataProviderError> {
        persister.fetch(type: Int.self, path: Self.numberOfCommentsPath(for: photoID))
            .catch { _ in
                // Fetching from the API when persitance
                // does not return values
                self.api.comments(for: photoID)
                    .map { $0.count }
                    .eraseToAnyPublisher()
        }
        .mapError { _ in PhotoDataProviderError.error }
        .eraseToAnyPublisher()
    }

    func persist(numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never> {
        persister.persist(t: numberOfComments, path: Self.numberOfCommentsPath(for: photoID))
            .map { numberOfCommentsResult in
                switch numberOfCommentsResult {
                case .persisted:
                    return ()
                case .dataAlreadyPresent:
                    return () // TODO return an error
                }
        }
                .replaceError(with: ()) // TODO
                .eraseToAnyPublisher()
    }
}

extension NumberOfCommentsDataProvider {
    private static func numberOfCommentsPath(for photoID: Int) -> String {
        "/Photo\(photoID)/numberOfComments"
    }
}

enum PhotoDataProviderError: Error {
    case error
}

#if DEBUG
struct AuthorDataProviderFixture: AuthorDataProviderProtocol {
    func fetch(
        albumID: Int,
        photoID: Int
    ) -> AnyPublisher<String, PhotoDataProviderError> {
        Just("Napoleone Bonaparte")
            .setFailureType(to: PhotoDataProviderError.self)
            .eraseToAnyPublisher()
    }

    func persist(author: String, photoID: Int) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}

struct NumberOfCommentsDataProviderFixture: NumberOfCommentsDataProviderProtocol {
    func fetch(
        photoID: Int
    ) -> AnyPublisher<Int, PhotoDataProviderError> {
        Just(11)
            .setFailureType(to: PhotoDataProviderError.self)
            .eraseToAnyPublisher()
    }

    func persist(numberOfComments: Int, photoID: Int) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}
#endif
