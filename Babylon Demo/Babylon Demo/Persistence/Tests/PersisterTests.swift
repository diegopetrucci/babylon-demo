import XCTest
import Combine
import Disk
@testable import Babylon_Demo

// Integration tests
final class PersisterTests: XCTestCase {
    let path = "/path"

    func test_persist_whenDataNotPresent() {
        defer { try! Disk.remove(path, from: .caches) }

        let persister = Persister()

        let expectation = XCTestExpectation() // TODO

        let _ = persister.persist(t: 1, path: path)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    expectation.fulfill()
                }
            }) { result in
                switch result {
                case .persisted:
                    XCTAssert(true)
                case .dataAlreadyPresent:
                    XCTFail("Data should not be already present.")
                }
        }
    }

    // This test could be merged with the previous one,
    // but I've chosen to keep them separate to be
    // slightly more precise with the errors given
    func test_persist_whenDataIsAlreadyPresent() {
        defer { try! Disk.remove(path, from: .caches) }
        
        let persister = Persister()

        let expectation = XCTestExpectation() // TODO

        // Persist the data
        let _ = persister.persist(t: 1, path: path)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    expectation.fulfill()
                }
            }) { result in
                switch result {
                case .persisted:
                    return
                case .dataAlreadyPresent:
                    XCTFail("Data should not be already present.")
                }
        }

        // Check that is correctly recognizing the data is already persisted
        let _ = persister.persist(t: 1, path: path)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    expectation.fulfill()
                }
            }) { result in
                switch result {
                case .persisted:
                    XCTFail("Data should already be present.")
                case .dataAlreadyPresent:
                    XCTAssert(true)
                }
        }
    }
}
