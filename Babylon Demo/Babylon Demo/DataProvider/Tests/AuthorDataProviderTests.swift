import Combine
import XCTest
@testable import Babylon_Demo

final class AuthorDataProviderTests: XCTestCase {
    func test_fetchAuthor_fromAPI() {
        let dataProvider = AuthorDataProvider(
            api: APIFixture(),
            persister: AuthorPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetch(albumID: 1, photoID: 2)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case let .failure(error):
                        XCTFail(error.localizedDescription)
                    }
            }) { author in
                XCTAssertEqual("Ted Chiang", author)
        }
    }

    func test_fetchAuthor_fromPersistence() {
        let expectedAuthor = "Liu Cixin"

        let dataProvider = AuthorDataProvider(
            api: APIFixture(),
            persister: AuthorPersisterFixture(author: expectedAuthor)
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetch(albumID: 1, photoID: 2)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { author in
                XCTAssertEqual(expectedAuthor, author)
        }
    }

    func test_persist_whenDataIsAlreadyPresent() {
        let expectedAuthor = "Liu Cixin"

        let dataProvider = AuthorDataProvider(
            api: APIFixture(),
            persister: AuthorPersisterFixture(
                author: expectedAuthor
            )
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(
            author: expectedAuthor,
            photoID: 3
        )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case let .failure(error):
                        XCTFail(error.localizedDescription)
                    }
                },
                receiveValue: { _ in }
            )
    }

    func test_persist_whenDataIsNotAlreadyPresent() {
        let dataProvider = AuthorDataProvider(
            api: APIFixture(),
            persister: AuthorPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(author: "Ted Chiang", photoID: 5)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }

    // TODO: test errors
}

struct AuthorPersisterFixture: PersisterProtocol {
    var author: String?

    // This is kind of ugly but it's the only way I've found
    // to erase the two types `String` and `Int`.
    func fetch<T: Codable>(type: T.Type, path: String) -> AnyPublisher<T, PersisterError> {
        let _author = author ?? "Ted Chiang"

        return Just(_author as! T)
        .setFailureType(to: PersisterError.self)
        .eraseToAnyPublisher()
    }

    func persist<T: Codable>(t: T, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        guard author == nil else {
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        return Just(.persisted)
            .setFailureType(to: PersisterError.self)
            .eraseToAnyPublisher()
    }
}

