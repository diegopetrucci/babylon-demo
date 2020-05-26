import Combine
import XCTest
@testable import Babylon_Demo

final class NumberOfCommentsDataProviderTests: XCTestCase {
    func test_fetchNumberOfComments_fromAPI() {
        let dataProvider = NumberOfCommentsDataProvider(
            api: APIFixture(),
            persister: NumberOfCommentsPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetch(photoID: 2)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case let .failure(error):
                        XCTFail(error.localizedDescription)
                    }
            }) { numberOfComments in
                XCTAssertEqual(42, numberOfComments)
        }
    }

    func test_fetchNumberOfComments_fromPersistence() {
        let expectedNumberOfComments = 1337

        let dataProvider = NumberOfCommentsDataProvider(
            api: APIFixture(),
            persister: NumberOfCommentsPersisterFixture(numberOfComments: expectedNumberOfComments)
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetch(photoID: 2)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { numberOfComments in
                XCTAssertEqual(expectedNumberOfComments, numberOfComments)
        }
    }

    func test_persist_whenDataIsAlreadyPresent() {
        let expectedNumberOfComments = 1337

        let dataProvider = NumberOfCommentsDataProvider(
            api: APIFixture(),
            persister: NumberOfCommentsPersisterFixture(numberOfComments: expectedNumberOfComments)
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(
            numberOfComments: expectedNumberOfComments,
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
        let dataProvider = NumberOfCommentsDataProvider(
            api: APIFixture(),
            persister: NumberOfCommentsPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(numberOfComments: 1337, photoID: 5)
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

struct NumberOfCommentsPersisterFixture: PersisterProtocol {
    var numberOfComments: Int?

    // This is kind of ugly but it's the only way I've found
    // to erase the two types `String` and `Int`.
    func fetch<T: Codable>(type: T.Type, path: String) -> AnyPublisher<T, PersisterError> {
        let _numberOfComments = numberOfComments ?? 42

        return Just(_numberOfComments as! T)
        .setFailureType(to: PersisterError.self)
        .eraseToAnyPublisher()
    }

    func persist<T: Codable>(t: T, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        guard numberOfComments == nil else {
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        return Just(.persisted)
            .setFailureType(to: PersisterError.self)
            .eraseToAnyPublisher()
    }
}

