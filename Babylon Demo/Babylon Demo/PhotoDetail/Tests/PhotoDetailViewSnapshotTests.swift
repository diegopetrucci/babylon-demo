import XCTest
import SnapshotTesting
import SwiftUI
@testable import Babylon_Demo

final class PhotoDetailViewSnapshotTests: XCTestCase {
    func test_loading() {
        assertSnapshot(
            matching: PhotoDetailView(
                viewModel: .fixture(status: .loading)
            ),
            as: .image()
        )
    }

    // TODO: understand why this `fatalError`s
    func test_loaded() {
        assertSnapshot(
            matching: PhotoDetailView(
                viewModel: .fixture(status: .loaded(.fixture()))
            ),
            as: .image()
        )
    }

    func test_notLoaded() {
        assertSnapshot(
            matching: PhotoDetailView(
                viewModel: .fixture(status: .notLoaded)
            ),
            as: .image()
        )
    }

    func test_persisted() {
        assertSnapshot(
            matching: PhotoDetailView(
                viewModel: .fixture(status: .persisted(.fixture()))
            ),
            as: .image()
        )
    }
}
