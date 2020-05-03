import Combine
import Foundation
import class SwiftUI.UIImage
import Then

final class ListViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private var input = PassthroughSubject<Event.UI, Never>()

    #if DEBUG
    init(state: State, api: API = JSONPlaceholderAPI()) {
        self.state = state

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(input.eraseToAnyPublisher()),
                Self.whenLoadingMetadata(api: api),
                Self.whenLoadingThumbnail(api: api)
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    #endif

    init(api: API = JSONPlaceholderAPI()) {
        state = .init(status: .loading)

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(input.eraseToAnyPublisher()),
                Self.whenLoadingMetadata(api: api),
                Self.whenLoadingThumbnail(api: api)
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
        case let .loadedThumbnails(images, indexes):
            return state.with { state in
                // TODO I don't particulary like this solution of doing `index - firstIndex`
                //      It works, but it feels like a hack.
                guard let firstIndex = indexes.first
                else { fatalError("There cannot be no indexes.") }

                indexes.forEach { index in
                    if let thumbnail = state.thumbnails.first(where: { $0.id == state.elements[index].id }) {
                        state.thumbnails.remove(thumbnail)
                        state.thumbnails.insert(
                            ListView.Thumbnail(
                                id: state.elements[index].id,
                                url: state.elements[index].thumbnailURL,
                                image: images[index - firstIndex],
                                size: images[index - firstIndex]?.size
                            )
                        )
                    } else {
                        state.thumbnails.insert(
                            ListView.Thumbnail(
                                id: state.elements[index].id,
                                url: state.elements[index].thumbnailURL,
                                image: images[index - firstIndex],
                                size: images[index - firstIndex]?.size
                            )
                        )
                    }
                }

                state.status = .loaded
            }
        case let .ui(.onListCellAppear(index)):
            // This is to avoid having multiple cells shown at the same time
            // to trigger this. The poor's man lock.
            guard case .loaded = state.status else { return state }

            return state.with {
//                // A better solution would be for the API to be
//                // paginated. Since the images are small I feel
//                // like downloading 10 of them at a time
//                // is a good compromise, given that less than
//                // that are shown in the screen without scrolling
                let next9URLs = Array(state.elements[index...(index + 8)])
                    .map { $0.thumbnailURL }

                $0.status = .loadingThumbnail(
                    indexes: Array(index...(index + 8)),
                    urls: next9URLs
                )
            }
        }
    }
}

extension ListViewModel {
    func send(_ event: Event.UI) {
        input.send(event)
    }
}

extension ListViewModel {
    private static func userInput(_ input: AnyPublisher<Event.UI, Never>) -> Feedback<State, Event> {
        Feedback(run: { _ in
            input
                .map(Event.ui)
                .eraseToAnyPublisher()
        })
    }

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

    private static func whenLoadingThumbnail(
        api: API
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loadingThumbnail(indexes, urls) = state.status
            else { return Empty().eraseToAnyPublisher() }

            let imagePublishers: [AnyPublisher<UIImage?, Never>] = urls.map { api.image(for: $0) }

            return Publishers.MergeMany(imagePublishers)
                .collect()
                .map { Event.loadedThumbnails(image: $0, indexes: indexes) }
                .eraseToAnyPublisher()
        }
    }
}

extension ListViewModel {
    struct State: Then {
        var status: Status
        var thumbnails = Set<ListView.Thumbnail>()
        var elements: [ListView.Element] = []
    }

    enum Status: Equatable {
        case loading
        case loaded
        case loadingThumbnail(indexes: [Int], urls: [URL])
        case error
    }

    enum Event {
        case loadedMetadata([ListView.Element])
        case failedToLoadMetadata
        case loadedThumbnails(image: [UIImage?], indexes: [Int])
        case ui(UI)

        enum UI {
            case onListCellAppear(_ index: Int)
        }
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
        thumbnailURL: photo.thumbnailURL,
        thumbnail: ListView.Thumbnail(
            id: photo.id,
            url: photo.thumbnailURL,
            image: nil,
            size: nil
        ),
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
                elements: [.fixture(isFavourite: true), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture(), .fixture()]
            ),
            api: APIFixture()
        )
    }
}
#endif
