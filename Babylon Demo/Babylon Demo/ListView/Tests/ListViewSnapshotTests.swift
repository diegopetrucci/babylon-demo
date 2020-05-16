import XCTest
import Combine
import SnapshotTesting
@testable import Babylon_Demo

final class ListViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()

        record = false
    }

    func test_loading() {
        assertSnapshot(
            matching: ListView(viewModel: .fixture(status: .loading)),
            as: .image()
        )
    }

    func test_loaded() {
        assertSnapshot(
            matching: ListView(viewModel: .fixture(status: .loaded)),
            as: .image()
        )
    }

    func test_error() {
        assertSnapshot(
            matching: ListView(viewModel: .fixture(status: .error)),
            as: .image()
        )
    }

    func test_persisted() {
        assertSnapshot(
            matching: ListView(viewModel: .fixture(status: .persisted)),
            as: .image()
        )
    }
}
