import Combine
import XCTest
@testable import Babylon_Demo

final class ListDataProviderTests: XCTestCase {
    func test_fetchMetadata_fromAPI() {
        let dataProvider = ListDataProvider(
            api: APIFixture(),
            persister: ListDataPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchMetadata()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { elements in
                let expected = [
                    ListView.Element(
                        id: 2,
                        title: "et soluta est",
                        photoURL: URL(string: "http://google.com")!,
                        thumbnailURL: URL(string: "http://google.com")!,
                        isFavourite: false,
                        albumID: 21
                    ),
                    ListView.Element(
                        id: 9,
                        title: "et soluta est",
                        photoURL: URL(string: "http://google.com")!,
                        thumbnailURL: URL(string: "http://google.com")!,
                        isFavourite: false,
                        albumID: 93
                    ),
                    ListView.Element(
                        id: 46,
                        title: "et soluta est",
                        photoURL: URL(string: "http://google.com")!,
                        thumbnailURL: URL(string: "http://google.com")!,
                        isFavourite: false,
                        albumID: 31
                    )
                ]
                
                XCTAssertEqual(expected, elements)
        }
    }

    func test_fetchMetadata_fromPersistence() {
        let expectedElements = [
            ListView.Element.fixture(),
            ListView.Element.fixture(isFavourite: true)
        ]

        let dataProvider = ListDataProvider(
            api: APIFixture(),
            persister: ListDataPersisterFixture(elements: expectedElements)
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchMetadata()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { elements in
                XCTAssertEqual(expectedElements, elements)
        }
    }

    func test_persist_whenDataIsAlreadyPresent() {
        let elements = [
            ListView.Element.fixture(isFavourite: true),
            ListView.Element.fixture(),
            ListView.Element.fixture(),
            ListView.Element.fixture()
        ]

        let dataProvider = ListDataProvider(
            api: APIFixture(),
            persister: ListDataPersisterFixture(elements: elements)
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(elements: elements)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }, receiveValue: { _ in })
    }

    func test_persist_whenDataIsNotAlreadyPresent() {
        let dataProvider = ListDataProvider(
            api: APIFixture(),
            persister: ListDataPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(elements: [ListView.Element.fixture(isFavourite: true)])
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

struct ListDataPersisterFixture: PersisterProtocol {
    var elements: [ListView.Element] = []

    func fetch<T: Codable>(type: T.Type, path: String) -> AnyPublisher<T, PersisterError> {
        guard elements.isNotEmpty else {
            return Fail<T, PersisterError>(error: .error)
                .eraseToAnyPublisher()
        }

        return Just(elements as! T)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
    }

    func persist<T: Codable>(t: T, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        guard elements.isNotEmpty else {
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        return Just(.persisted)
            .setFailureType(to: PersisterError.self)
            .eraseToAnyPublisher()
    }
}
