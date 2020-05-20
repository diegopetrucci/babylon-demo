import Combine
import XCTest
@testable import Babylon_Demo

final class PhotoDetailDataProviderTests: XCTest {
    func test_fetchAuthorAndNumberOfComments_fromAPI() {
        let dataProvider = PhotoDetailDataProvider(
            api: APIFixture(),
            persister: PhotoDetailPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchAuthorAndNumberOfComments(albumID: 1, photoID: 2)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { author, numberOfComments in
                XCTAssertEqual("author", author)
                XCTAssertEqual(1, numberOfComments)
        }
    }

    func test_fetchAuthorAndNumberOfComments_fromPersistence() {
        let expectedAuthor = "Liu Cixin"
        let expectedNumberOfComments = 83

        let dataProvider = PhotoDetailDataProvider(
            api: APIFixture(),
            persister: PhotoDetailPersisterFixture(
                author: expectedAuthor,
                numberOfComments: expectedNumberOfComments
            )
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchAuthorAndNumberOfComments(albumID: 1, photoID: 2)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { author, numberOfComments in
                XCTAssertEqual(expectedAuthor, author)
                XCTAssertEqual(expectedNumberOfComments, numberOfComments)
        }
    }

    func test_persist_whenDataIsAlreadyPresent() {
        let expectedAuthor = "Liu Cixin"
        let expectedNumberOfComments = 83

        let dataProvider = PhotoDetailDataProvider(
            api: APIFixture(),
            persister: PhotoDetailPersisterFixture(
                author: expectedAuthor,
                numberOfComments: expectedNumberOfComments
            )
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persist(
            author: expectedAuthor,
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
        let dataProvider = PhotoDetailDataProvider(
            api: APIFixture(),
            persister: PhotoDetailPersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchAuthorAndNumberOfComments(albumID: 1, photoID: 2)
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

struct PhotoDetailPersisterFixture: PersisterProtocol {
    var author: String?
    var numberOfComments: Int?

    func fetch<T: Codable>(type: T.Type, path: String) -> AnyPublisher<T, PersisterError> {
        guard
            let author = author,
            let numberOfComments = numberOfComments
        else { return Fail<T, PersisterError>(error: .error) .eraseToAnyPublisher() }

        return Just((author, numberOfComments) as! T)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
    }

    func persist<T: Codable>(t: T, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        guard author == nil || numberOfComments == nil else {
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        return Just(.persisted)
            .setFailureType(to: PersisterError.self)
            .eraseToAnyPublisher()
    }
}

