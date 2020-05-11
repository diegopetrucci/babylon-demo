import Combine
import Foundation
import class SwiftUI.UIImage
import Then

final class ListViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()

    #if DEBUG
    init(state: State, api: API = JSONPlaceholderAPI()) {
        self.state = state

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoadingMetadata(api: api)
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    #endif

    init(api: API = JSONPlaceholderAPI()) {
        state = .init(status: .loading, api: api)

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoadingMetadata(api: api)
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

extension ListViewModel {
    private static func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case let .loadedMetadata(elements):
            return state.with {
                $0.status = .loaded
                $0.elements = elements
            }
        case .failedToLoadMetadata:
            return state.with { $0.status = .error }
        }
    }
}

extension ListViewModel {
    private static func whenLoadingMetadata(api: API) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state.status else { return Empty().eraseToAnyPublisher() }

            // The API has no pagination, so given that this data
            // is loaded extremely fast I've decided to download it
            // in one go, decode it, and map it to `ListView.Element`.
            // Having a paginated API would definitely be better.
            return api.photos()
                .map { photos in photos.map(element(from:)) }
                .map { $0.sorted(by: Self.isSortedByFavourites) }
                .map(Event.loadedMetadata)
                .replaceError(with: Event.failedToLoadMetadata)
                .eraseToAnyPublisher()
        }
    }
}

extension ListViewModel {
    struct State: Then {
        var status: Status
        var elements: [ListView.Element] = []

        private let api: API

        init(
            status: Status,
            elements: [ListView.Element] = [],
            api: API
        ) {
            self.status = status
            self.elements = elements
            self.api = api
        }

        // TODO this should be the job of a coordinator of sorts
        //      but unfortunately there does not seem to be a nice
        //      patter for SwiftUI yet.
        func destination(for index: Array<ListView.Element>.Index) -> PhotoDetailView {
            print(index)
            let element = elements[index]

            return PhotoDetailView(
                viewModel: .init(
                    title: element.title,
                    isFavourite: element.isFavourite,
                    albumID: element.albumID,
                    photoID: element.id,
                    photoURL: element.photoURL,
                    api: api
                )
            )
        }

        func asyncImageView(for index: Array<ListView.Element>.Index) -> AsyncImageView {
            let element = elements[index]

            return AsyncImageView(
                viewModel: AsyncImageViewModel(
                    url: element.thumbnailURL,
                    imagePath: "/ListView/\(element.id)",
                    dataProvider: AsyncImageDataProvider()
                )
            )
        }
    }

    enum Status: Equatable {
        case loading
        case loaded
        case error
    }

    enum Event {
        case loadedMetadata([ListView.Element])
        case failedToLoadMetadata
    }
}

extension ListViewModel {
    static func isSortedByFavourites(firstElement: ListView.Element, secondElement: ListView.Element) -> Bool {
        switch (firstElement.isFavourite, secondElement.isFavourite) {
        case (true, true), (false, false):
            return firstElement.id < secondElement.id
        case (true, false):
            return true
        case (false, true):
            return false
        }
    }
}

private func element(from photo: Photo) -> ListView.Element {
    ListView.Element(
        id: photo.id,
        title: photo.title,
        photoURL: photo.url,
        thumbnailURL: photo.thumbnailURL,
        isFavourite: false,
        albumID: photo.albumID
    )
}

#if DEBUG
extension ListViewModel {
    static func fixture() -> ListViewModel {
        .init(
            state: .init(
                status: .loaded,
                elements: [.fixture(isFavourite: true), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture()],
                api: APIFixture()
            ),
            api: APIFixture()
        )
    }
}
#endif
