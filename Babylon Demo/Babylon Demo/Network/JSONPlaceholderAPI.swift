import Combine
import Foundation
import class UIKit.UIImage

protocol API {
    func photos() -> AnyPublisher<[Photo], RemoteError>
    func image(for url: URL) -> AnyPublisher<UIImage?, Never>
    func album(with albumID: Int) -> AnyPublisher<Album, RemoteError>
    func user(with userID: Int) -> AnyPublisher<User, RemoteError>
    func comments(for photoID: Int) -> AnyPublisher<[Comment], RemoteError>
}

struct JSONPlaceholderAPI {
    private let remote: Remoteable
    private let baseURL = URL(string: "http://jsonplaceholder.typicode.com/")!

    init(remote: Remoteable) {
        self.remote = remote
    }
}

extension JSONPlaceholderAPI: API {
    func photos() -> AnyPublisher<[Photo], RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("photos"), jsonDecoder: JSONDecoder())
    }

    func image(for url: URL) -> AnyPublisher<UIImage?, Never> {
        remote.loadData(from: url)
            .map(UIImage.init)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    func album(with albumID: Int) -> AnyPublisher<Album, RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("albums/\(albumID)"), jsonDecoder: JSONDecoder())
    }

    func user(with userID: Int) -> AnyPublisher<User, RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("users/\(userID)"), jsonDecoder: JSONDecoder())
    }

    func comments(for photoID: Int) -> AnyPublisher<[Comment], RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("photos/\(photoID)/comments"), jsonDecoder: JSONDecoder())
    }
}

#if DEBUG
struct APIFixture: API {
    func photos() -> AnyPublisher<[Photo], RemoteError> {
        Just<[Photo]>([.fixture(), .fixture(id: 2, albumID: 21), .fixture(id: 9, albumID: 93)])
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }

    func image(for url: URL) -> AnyPublisher<UIImage?, Never> {
        Just<UIImage?>(UIImage(named: "thumbnail_fixture"))
            .setFailureType(to: Never.self)
            .eraseToAnyPublisher()
    }

    func album(with albumID: Int) -> AnyPublisher<Album, RemoteError> {
        Just<Album>(.fixture())
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }

    func user(with userID: Int) -> AnyPublisher<User, RemoteError> {
        Just<User>(.fixture())
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }

    func comments(for photoID: Int) -> AnyPublisher<[Comment], RemoteError> {
        Just<[Comment]>([.fixture(), .fixture(), .fixture()])
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }
}
#endif
