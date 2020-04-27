import Combine
import Foundation
import class UIKit.UIImage
import Then

final class PhotoDetailViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event.UI, Never>()

    init(
        element: ListView.Element,
        albumID: Int,
        photoID: Int,
        photoURL: URL,
        api: API = JSONPlaceholderAPI()
    ) {
        let initialState = State(
            status: .idle,
            title: element.title,
            image: nil,
            author: nil,
            numberOfComments: nil,
            isFavourite: element.isFavourite
        )

        state = initialState

        Publishers.system(
            initial: initialState,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(input: input.eraseToAnyPublisher()),
                Self.whenLoading(
                    imageURL: element.photoURL,
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
    static func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case let .loaded(image, author, numberOfComments):
            return state.with {
                $0.status = .loaded
                $0.image = image
                $0.author = author
                $0.numberOfComments = numberOfComments
            }
        case let .ui(ui):
            switch ui {
            case .onAppear:
                return state.with { $0.status = .loading }
            case .tappedFavouriteButton:
                return state.with { $0.isFavourite.toggle() } // TODO does this work?
            }
        }
    }
}

extension PhotoDetailViewModel {
    static func userInput(input: AnyPublisher<Event.UI, Never>) -> Feedback<State, Event> {
        Feedback(run: { _ in
            return input
                .map(Event.ui)
                .eraseToAnyPublisher()
        })
    }

    static func whenLoading(
        imageURL: URL?,
        albumID: Int,
        photoID: Int,
        api: API
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .idle = state.status else { return Empty().eraseToAnyPublisher() }

            let imagePublisher = (imageURL != nil)
                ? api.image(for: imageURL!) // TODO sigh…
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
                : Just<UIImage?>(nil)
                    .setFailureType(to: Never.self)
                    .eraseToAnyPublisher()

            let authorPublisher = api.album(with: albumID)
                .flatMap { api.user(with: $0.userID) }
                .map { $0.name }
                .replaceError(with: nil)
                .eraseToAnyPublisher()

            let numberOfCommentsPublisher = api.numberOfComments(for: photoID)
                .map(String.init) // TODO
                .replaceError(with: nil)
                .eraseToAnyPublisher()

            return Publishers.CombineLatest3(
                imagePublisher,
                authorPublisher,
                numberOfCommentsPublisher
            )
                .replaceError(with: (nil, nil, nil))
                .map { (image, author, numberOfComments) in
                    Event.loaded(image: image, author: author, numberOfComments: numberOfComments)
            }
            .eraseToAnyPublisher()
        }
    }
}

extension PhotoDetailViewModel {
    struct State: Then {
        var status: Status
        var title: String
        var image: UIImage?
        var author: String?
        var numberOfComments: String?
        var isFavourite: Bool // TODO write to storage
    }

    enum Status {
        case idle
        case loading
        case loaded
        case noImageLoaded
    }

    enum Event {
        case loaded(image: UIImage?, author: String?, numberOfComments: String?)
        case ui(UI)

        enum UI {
            case onAppear
            case tappedFavouriteButton
        }
    }
}
