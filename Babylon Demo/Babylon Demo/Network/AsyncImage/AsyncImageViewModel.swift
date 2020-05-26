import Combine
import class UIKit.UIImage
import Foundation
import Then
import Disk

final class AsyncImageViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event.UI, Never>()

    init(
        url: URL,
        dataProvider: AsyncImageDataProviderProtocol
    ) {
        self.state = State(
            status: .idle
        )

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(url: url, dataProvider: dataProvider),
                Self.whenLoaded(url: url, dataProvider: dataProvider),
                Self.userInput(input.eraseToAnyPublisher())
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

extension AsyncImageViewModel {
    func send(event: Event.UI) {
        input.send(event)
    }
}

extension AsyncImageViewModel {
    private static func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case .ui(.onAppear):
            // if we already have an image loaded we keep the loaded state,
            // otherwise we go back to .idle to give it another chance to load
            if case .loaded = state.status {
                return state
            } else {
                return state.with { $0.status = .loading }
            }
        case .ui(.onDisappear):
            // if we already have an image loaded we keep the loaded state,
            // otherwise we go back to .idle to give it another chance to load
            if case .loaded = state.status {
                return state
            } else {
                return state.with { $0.status = .idle }
            }
        case let .loaded(image):
            if let image = image {
                return state.with { $0.status = .loaded(image: image) }
            } else {
                return state.with { $0.status = .failed(placeholder: Self.placeholder) }
            }
        case .failedToLoad:
            return state
        case .persisted:
            return state
        }
    }
}

extension AsyncImageViewModel {
    private static func whenLoading(
        url: URL,
        dataProvider: AsyncImageDataProviderProtocol
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state.status else { return Empty().eraseToAnyPublisher() }

            return dataProvider.fetchImage(url: url)
                .map(Event.loaded)
                .replaceError(with: .failedToLoad)
                .eraseToAnyPublisher()
        }
    }

    private static func whenLoaded(
        url: URL,
        dataProvider: AsyncImageDataProviderProtocol
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loaded(image) = state.status else { return Empty().eraseToAnyPublisher() }

            return dataProvider.persistImage(image: image, url: url)
                .map{ _ in Event.persisted }
                .eraseToAnyPublisher()
        }
    }

    private static func userInput(_ input: AnyPublisher<Event.UI, Never>) -> Feedback<State, Event> {
        Feedback(run: { _ in
            input
                .map(Event.ui)
                .eraseToAnyPublisher()
        })
    }
}

extension AsyncImageViewModel {
    struct State: Then {
        var status: Status

        // Note: workaround of SwiftUI views not supporting
        // if-lets or switches
        var image: UIImage {
            if case let .loaded(image) = status {
                return image
            } else {
                fatalError("This should never be called, the view is misconfigured.")
            }
        }
    }

    enum Status: Equatable {
        case idle
        case loading
        case loaded(image: UIImage)
        case failed(placeholder: UIImage)
    }

    enum Event {
        case ui(UI)
        case loaded(UIImage?)
        case failedToLoad
        case persisted

        enum UI {
            case onAppear
            case onDisappear
        }
    }
}

extension AsyncImageViewModel {
    static var placeholder: UIImage {
        UIImage(named: "thumbnail_fixture")!
    }
}

#if DEBUG
extension AsyncImageViewModel {
    static func fixture() -> AsyncImageViewModel {
        AsyncImageViewModel.init(
            url: .fixture(),
            dataProvider: AsyncImageDataProviderFixture()
        )
    }
}
#endif
