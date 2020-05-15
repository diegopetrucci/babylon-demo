import XCTest
import Combine
@testable import Babylon_Demo

final class JSONPlaceholderAPITests: XCTestCase {
    func test_fetchPhotos() {
        let remote = RemoteFixture(type: .photos)
        let api = JSONPlaceholderAPI(remote: remote)

        let expectation = XCTestExpectation() // TODO

        let _ = api.photos()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fatalError(error.localizedDescription)
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { receivedPhotos in
                    XCTAssertEqual(receivedPhotos, [.fixture(), .fixture(), .fixture()])
                }
        )
    }

    func test_fetchImage() {
        let remote = RemoteFixture(type: .image)
        let api = JSONPlaceholderAPI(remote: remote)

        let expectation = XCTestExpectation() // TODO

        let _ = api.image(for: .fixture())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fatalError(error.localizedDescription)
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { receivedImage in
                    XCTAssertNotNil(receivedImage)
                }
        )
    }

    func test_fetchAlbum() {
        let remote = RemoteFixture(type: .album)
        let api = JSONPlaceholderAPI(remote: remote)

        let expectation = XCTestExpectation() // TODO

        let _ = api.album(with: 3)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fatalError(error.localizedDescription)
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { album in
                    XCTAssertEqual(album, .fixture())
                }
        )
    }

    func test_fetchUser() {
        let remote = RemoteFixture(type: .album)
        let api = JSONPlaceholderAPI(remote: remote)

        let expectation = XCTestExpectation() // TODO

        let _ = api.user(with: 5)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fatalError(error.localizedDescription)
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { user in
                    XCTAssertEqual(user, .fixture())
                }
        )
    }

    func test_fetchNumberOfComments() {
        let remote = RemoteFixture(type: .album)
        let api = JSONPlaceholderAPI(remote: remote)

        let expectation = XCTestExpectation() // TODO

        let _ = api.comments(for: 2)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        fatalError(error.localizedDescription)
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { comments in
                    XCTAssertEqual(comments.count, 4)
                }
        )
    }
}

struct RemoteFixture: Remoteable {
    private let type: FixtureType

    init(type: FixtureType) {
        self.type = type
    }

    func load<T: Decodable>(from url: URL, jsonDecoder: JSONDecoder) -> AnyPublisher<T, RemoteError> {
        switch type {
        case .photos:
            return Just([Photo.fixture(), Photo.fixture(), Photo.fixture()] as? T)
                .compactMap(identity)
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        case .album:
            return Just(Album.fixture() as? T)
                .compactMap(identity)
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        case .user:
            return Just(User.fixture() as? T)
                .compactMap(identity)
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        case .comments:
            return Just([Comment.fixture(), Comment.fixture(), Comment.fixture(), Comment.fixture()] as? T)
                .compactMap(identity)
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        case .image:
            fatalError("Please use `loadData(imageURL:)` instead.")
        }
    }

    func loadData(from imageURL: URL) -> AnyPublisher<Data, RemoteError> {
        switch type {
        case .photos, .album, .user, .comments:
            fatalError("Please use `load(url:jsonDecoder:)` instead.")
        case .image:
            return Just(UIImage.fixture())
                .map { $0.pngData() }
                .compactMap(identity)
                .setFailureType(to: RemoteError.self)
                .eraseToAnyPublisher()
        }
    }

    enum FixtureType {
        case photos
        case image
        case album
        case user
        case comments
    }
}
