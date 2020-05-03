import Combine
import Foundation
import class UIKit.UIImage

protocol API {
    func photos() -> AnyPublisher<[Photo], RemoteError>
    func image(for url: URL) -> AnyPublisher<UIImage?, Never>
    func album(with albumID: Int) -> AnyPublisher<Album, RemoteError>
    func user(with userID: Int) -> AnyPublisher<User, RemoteError>
    func numberOfComments(for photoID: Int) -> AnyPublisher<Int, RemoteError>
}

struct JSONPlaceholderAPI {
    private let remote = Remote()
    private let baseURL = URL(string: "http://jsonplaceholder.typicode.com/")!
}

extension JSONPlaceholderAPI: API {
    func photos() -> AnyPublisher<[Photo], RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("photos"))
    }

    func image(for url: URL) -> AnyPublisher<UIImage?, Never> {
        remote.loadData(from: url)
            .map(UIImage.init)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

//    func images(for urls: [URL]) -> AnyPublisher<[UIImage?], Never> {
//        urls.map { url in
//            remote.loadData(from: url)
//            .map(UIImage.init)
//            .replaceError(with: nil)
//            .eraseToAnyPublisher()
//        }
//    }

    func album(with albumID: Int) -> AnyPublisher<Album, RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("albums/\(albumID)"))
    }

    func user(with userID: Int) -> AnyPublisher<User, RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("users/\(userID)"))
    }

    func numberOfComments(for photoID: Int) -> AnyPublisher<Int, RemoteError> {
        remote.load(from: baseURL.appendingPathComponent("photos/\(photoID)/comments"))
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

    func numberOfComments(for photoID: Int) -> AnyPublisher<Int, RemoteError> {
        Just<Int>(13)
            .setFailureType(to: RemoteError.self)
            .eraseToAnyPublisher()
    }
}
#endif
