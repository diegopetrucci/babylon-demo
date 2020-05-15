import Combine
import Foundation
import class SwiftUI.UIImage
import Then

final class ListViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()

    #if DEBUG
    init(state: State) {
        self.state = state

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoadingMetadata(dataProvider: ListDataProviderFixture()),
                Self.whenLoaded(dataProvider: ListDataProviderFixture())
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    #endif

    init(dataProvider: ListDataProviderProtocol, api: API = JSONPlaceholderAPI(remote: Remote())) {
        state = .init(status: .loading, api: api)

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoadingMetadata(dataProvider: dataProvider),
                Self.whenLoaded(dataProvider: dataProvider)
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
        case .persisted:
            return state.with { $0.status = .persisted }
        }
    }
}

extension ListViewModel {
    private static func whenLoadingMetadata(
        dataProvider: ListDataProviderProtocol
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state.status else { return Empty().eraseToAnyPublisher() }

            return dataProvider.fetchMetadata()
                .map(Event.loadedMetadata)
                .replaceError(with: Event.failedToLoadMetadata)
                .eraseToAnyPublisher()
        }
    }

    private static func whenLoaded(dataProvider: ListDataProviderProtocol) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loaded = state.status else { return Empty().eraseToAnyPublisher() }

            return dataProvider.persist(elements: state.elements)
                .map { _ in Event.persisted }
                .eraseToAnyPublisher()
        }
    }
}

// TODO add a save data

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
            let element = elements[index]

            return PhotoDetailView(
                viewModel: .init(
                    title: element.title,
                    isFavourite: element.isFavourite,
                    albumID: element.albumID,
                    photoID: element.id,
                    photoURL: element.photoURL,
                    api: api,
                    dataProvider: PhotoDetailDataProvider(api: api)
                )
            )
        }

        func asyncImageView(for index: Array<ListView.Element>.Index) -> AsyncImageView {
            let element = elements[index]

            return AsyncImageView(
                viewModel: AsyncImageViewModel(
                    url: element.thumbnailURL,
                    imagePath: "/ListView/\(element.id)",
                    dataProvider: AsyncImageDataProvider(api: api) // TODO the VM should not be creating this
                )
            )
        }
    }

    enum Status: Equatable {
        case loading
        case loaded
        case persisted
        case error
    }

    enum Event {
        case loadedMetadata([ListView.Element])
        case failedToLoadMetadata
        case persisted
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

#if DEBUG
extension ListViewModel {
    static func fixture() -> ListViewModel {
        .init(
            dataProvider: ListDataProviderFixture(),
            api: APIFixture()
        )
    }
}
#endif
