import Combine
import XCTest
@testable import Babylon_Demo

final class AsyncImageDataProviderTests: XCTestCase {
    func test_fetchImage_fromAPI() {
        let dataProvider = AsyncImageDataProvider(
            api: APIFixture(),
            persister: ImagePersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchImage(url: .fixture())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { image in
                XCTAssertEqual(UIImage.fixture(), image)
        }
    }

    func test_fetchImage_fromPersistence() {
        let dataProvider = AsyncImageDataProvider(
            api: APIFixture(),
            persister: ImagePersisterFixture(image: .fixture())
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.fetchImage(url: .fixture())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
            }) { image in
                XCTAssertEqual(UIImage.fixture(), image)
        }
    }

    func test_persist_whenDataIsAlreadyPresent() {
       let dataProvider = AsyncImageDataProvider(
            api: APIFixture(),
            persister: ImagePersisterFixture(image: .fixture())
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persistImage(image: .fixture(), url: .fixture())
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
        let dataProvider = AsyncImageDataProvider(
            api: APIFixture(),
            persister: ImagePersisterFixture()
        )

        let expectation = XCTestExpectation() // TODO

        let _ = dataProvider.persistImage(image: .fixture(), url: .fixture())
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

struct ImagePersisterFixture: ImagePersisterProtocol {
    var image: UIImage?

    func fetch(path: String) -> AnyPublisher<UIImage, PersisterError> {
        guard let image = image else { return Fail<UIImage, PersisterError>(error: .error) .eraseToAnyPublisher() }

        return Just(image)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
    }

    func persist(uiImage: UIImage, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        guard image == nil else {
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        return Just(.persisted)
            .setFailureType(to: PersisterError.self)
            .eraseToAnyPublisher()
    }
}

