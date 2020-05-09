import Combine
import Foundation
import class UIKit.UIImage
import Then

final class PhotoDetailViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event.UI, Never>()

    #if DEBUG
    init(
        state: State,
        element: ListView.Element,
        albumID: Int,
        photoID: Int,
        photoURL: URL,
        api: API = JSONPlaceholderAPI()
    ) {
        self.state = state

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(input: input.eraseToAnyPublisher()),
                Self.whenLoading(
                    albumID: albumID,
                    photoID: photoID,
                    api: api)
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    #endif

    init(
        element: ListView.Element,
        albumID: Int,
        photoID: Int,
        photoURL: URL,
        api: API = JSONPlaceholderAPI()
    ) {
        state = State(
            status: .idle,
            photoURL: photoURL,
            title: element.title,
            isFavourite: element.isFavourite
        )

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(input: input.eraseToAnyPublisher()),
                Self.whenLoading(
                    albumID: albumID,
                    photoID: photoID,
                    api: api)
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

extension PhotoDetailViewModel {
    func send(event: Event.UI) {
        input.send(event)
    }
}

extension PhotoDetailViewModel {
    private static func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case let .loaded(author, numberOfComments):
            return state.with {
                $0.status = .loaded(
                    title: state.title,
                    author: author,
                    numberOfComments: numberOfComments,
                    isFavourite: state.isFavourite
                )
            }
        case let .ui(ui):
            switch ui {
            case .onAppear:
                // We want to avoid unnecessarily double-reloading
                if case .loaded = state.status { return state }

                return state.with { $0.status = .loading }
            case .tappedFavouriteButton:
                return state.with { $0.isFavourite.toggle() } // TODO does this work?
            }
        }
    }
}

extension PhotoDetailViewModel {
    private static func userInput(input: AnyPublisher<Event.UI, Never>) -> Feedback<State, Event> {
        Feedback(run: { _ in
            input
                .map(Event.ui)
                .eraseToAnyPublisher()
        })
    }

    private static func whenLoading(
        albumID: Int,
        photoID: Int,
        api: API
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state.status else { return Empty().eraseToAnyPublisher() }

            let authorPublisher = api.album(with: albumID)
                .flatMap { api.user(with: $0.userID) }
                .map { $0.name }
                .replaceError(with: nil)
                .eraseToAnyPublisher()

            let numberOfCommentsPublisher = api.numberOfComments(for: photoID)
                .map(String.init) // TODO
                .replaceError(with: nil)
                .eraseToAnyPublisher()

            return Publishers.CombineLatest(
                authorPublisher,
                numberOfCommentsPublisher
            )
                .replaceError(with: (nil, nil))
                .map { (author, numberOfComments) in
                    Event.loaded(author: author, numberOfComments: numberOfComments)
            }
            .eraseToAnyPublisher()
        }
    }
}

extension PhotoDetailViewModel {
    struct State: Then {
        var status: Status

        let photoURL: URL

        // This is a temporary workaround for SwiftUI not having
        // `switch`es or `if-let`s
        var props: (String, String?, String?, Bool) {
            guard case let .loaded(title, author, numberOfComments, isFavourite) = status
            else { return ("", nil, nil, false) }

            return (title, author, numberOfComments, isFavourite)
        }

        fileprivate var title: String
        fileprivate var isFavourite: Bool // TODO write to storage
    }

    enum Status: Equatable {
        case idle
        case loading
        case loaded(title: String, author: String?, numberOfComments: String?, isFavourite: Bool)
        case notLoaded
    }

    enum Event {
        case loaded(author: String?, numberOfComments: String?)
        case ui(UI)

        enum UI {
            case onAppear
            case tappedFavouriteButton
        }
    }
}

#if DEBUG
extension PhotoDetailViewModel {
    static func fixture() -> Self {
        .init(
            state: .init(
                status: PhotoDetailViewModel.Status.loaded(
                    title: "The title of the photo is great",
                    author: "Napoleone Bonaparte",
                    numberOfComments: "11",
                    isFavourite: true
                ),
                photoURL: .fixture(),
                title: "The title of the photo is great",
                isFavourite: true
            ),
            element: .fixture(),
            albumID: 1,
            photoID: 2,
            photoURL: .fixture(),
            api: APIFixture()
        )
    }
}
#endif
