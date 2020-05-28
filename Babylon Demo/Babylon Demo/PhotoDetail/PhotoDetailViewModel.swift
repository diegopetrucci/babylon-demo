import Combine
import Foundation
import class UIKit.UIImage
import Then

final class PhotoDetailViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event.UI, Never>()

    // Unfortunately this cannot be extracted into an extension
    #if DEBUG
    init(
        state: State,
        title: String,
        isFavourite: Bool,
        albumID: Int,
        photoID: Int,
        photoURL: URL,
        authorDataProvider: AuthorDataProviderProtocol,
        numberOfCommentsDataProvider: NumberOfCommentsDataProviderProtocol
    ) {
        self.state = state

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(
                    input: input.eraseToAnyPublisher()
                ),
                Self.whenLoading(
                    albumID: albumID,
                    photoID: photoID,
                    title: title,
                    isFavourite: isFavourite,
                    photoURL: photoURL,
                    authorDataProvider: authorDataProvider,
                    numberOfCommentsDataProvider: numberOfCommentsDataProvider
                ),
                Self.whenPersisting(
                    authorDataProvider: authorDataProvider,
                    numberOfCommentsDataProvider: numberOfCommentsDataProvider,
                    photoID: photoID
                )
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    #endif

    init(
        title: String,
        isFavourite: Bool,
        albumID: Int,
        photoID: Int,
        photoURL: URL,
        api: API,
        authorDataProvider: AuthorDataProviderProtocol,
        numberOfCommentsDataProvider: NumberOfCommentsDataProviderProtocol
    ) {
        state = State(status: .idle, api: api)

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(
                    input: input.eraseToAnyPublisher()
                ),
                Self.whenLoading(
                    albumID: albumID,
                    photoID: photoID,
                    title: title,
                    isFavourite: isFavourite,
                    photoURL: photoURL,
                    authorDataProvider: authorDataProvider,
                    numberOfCommentsDataProvider: numberOfCommentsDataProvider
                ),
                Self.whenPersisting(
                    authorDataProvider: authorDataProvider,
                    numberOfCommentsDataProvider: numberOfCommentsDataProvider,
                    photoID: photoID
                )
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
        case let .loaded(photoDetail):
            return state.with { $0.status = .loaded(photoDetail) }
        case let .ui(ui):
            switch ui {
            case .onAppear:
                return state.with { $0.status = .loading }
            case .tappedFavouriteButton:
                return state // TODO
            }
        case .failedToLoad:
            return state // TODO
        case .persisted:
            return state.with { $0.status = .persisted(state.photoDetail) }
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
        title: String,
        isFavourite: Bool,
        photoURL: URL,
        authorDataProvider: AuthorDataProviderProtocol,
        numberOfCommentsDataProvider: NumberOfCommentsDataProviderProtocol
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state.status else { return Empty().eraseToAnyPublisher() }

            return Publishers.Zip(
                authorDataProvider.fetch(albumID: albumID, photoID: photoID),
                numberOfCommentsDataProvider.fetch(photoID: photoID)
            )
                .map { (author, numberOfComments) in
                    Event.loaded(
                        PhotoDetail(
                            id: photoID,
                            title: title,
                            author: author,
                            numberOfComments: numberOfComments,
                            isFavourite: isFavourite,
                            photoURL: photoURL
                        )
                    )
                }
                .replaceError(with: Event.failedToLoad)
                .eraseToAnyPublisher()
        }
    }

    private static func whenPersisting(
        authorDataProvider: AuthorDataProviderProtocol,
        numberOfCommentsDataProvider: NumberOfCommentsDataProviderProtocol,
        photoID: Int
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loaded = state.status else { return Empty().eraseToAnyPublisher() }

            return Publishers.Zip(
                authorDataProvider.persist(author: state.photoDetail.author, photoID: photoID),
                numberOfCommentsDataProvider.persist(
                    numberOfComments: state.photoDetail.numberOfComments,
                    photoID: photoID
                )
            )
                .map { _ in Event.persisted }
                .eraseToAnyPublisher()
        }
    }
}

extension PhotoDetailViewModel {
    struct State: Then {
        var status: Status

        // This is a temporary workaround for SwiftUI not having
        // `switch`es or `if-let`s
        var photoDetail: PhotoDetail {
            switch status {
            case let .loaded(photoDetail):
                return photoDetail
            case let .persisted(photoDetail):
                return photoDetail
            default:
                fatalError("This should not be called except when status is loaded.")
            }
        }

        private let api: API

        init(status: Status, api: API) {
            self.status = status
            self.api = api
        }

        func asyncImageView() -> AsyncImageView {
            AsyncImageView( // Note: same consideration as per the AsyncImageViewModel in ListView s
                viewModel: .init(
                    url: photoDetail.photoURL,
                    dataProvider: AsyncImageDataProvider(
                        api: api,
                        persister: ImagePersister()
                    )
                )
            )
        }
    }

    enum Status: Equatable {
        case idle
        case loading
        case loaded(PhotoDetail)
        case notLoaded
        case persisted(PhotoDetail)
    }

    enum Event {
        case loaded(PhotoDetail)
        case failedToLoad
        case persisted
        case ui(UI)

        enum UI {
            case onAppear
            case tappedFavouriteButton
        }
    }
}
extension PhotoDetailViewModel {
    struct PhotoDetail: Equatable {
        let id: Int
        let title: String
        let author: String
        let numberOfComments: Int
        var isFavourite: Bool
        let photoURL: URL // TODO temp until the AsyncImageView/Model is injectedb
    }
}

#if DEBUG
extension PhotoDetailViewModel {
    static func fixture(
        status: PhotoDetailViewModel.Status = .loaded(.fixture())
    ) -> Self {
        .init(
            state: .init(
                status: status,
                api: APIFixture()
            ),
            title: "The title of the photo is great",
            isFavourite: true,
            albumID: 1,
            photoID: 2,
            photoURL: .fixture(),
            authorDataProvider: AuthorDataProviderFixture(),
            numberOfCommentsDataProvider: NumberOfCommentsDataProviderFixture()
        )
    }
}

extension PhotoDetailViewModel.PhotoDetail {
    static func fixture() -> Self {
        .init(
            id: 2,
            title: "The title of the photo is great",
            author: "Napoleone Bonaparte",
            numberOfComments: 11,
            isFavourite: true,
            photoURL: URL(string: "https://google.com")!
        )
    }
}
#endif
