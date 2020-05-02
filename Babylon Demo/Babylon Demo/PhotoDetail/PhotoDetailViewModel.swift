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
        state = State(
            status: .loading,
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
            guard let image = image else { return state.with { $0.status = .notLoaded } }

            return state.with {
                $0.status = .loaded(
                    title: state.title,
                    image: image,
                    author: author,
                    numberOfComments: numberOfComments,
                    isFavourite: state.isFavourite
                )
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
            guard case .loading = state.status else { return Empty().eraseToAnyPublisher() }

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

        // This is a temporary workaround for SwiftUI not having
        // `switch`es or `if-let`s
        var props: (String, UIImage, String?, String?, Bool) {
            guard case let .loaded(title, image, author, numberOfComments, isFavourite) = status
            else { return ("", UIImage(named: "thumbnail_fixture")!, nil, nil, false) }

            return (title, image, author, numberOfComments, isFavourite)
        }

        fileprivate var title: String
        fileprivate var isFavourite: Bool // TODO write to storage
    }

    enum Status: Equatable {
        case loading
        case loaded(title: String, image: UIImage, author: String?, numberOfComments: String?, isFavourite: Bool)
        case notLoaded
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
