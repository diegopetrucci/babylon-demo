import Combine
import class UIKit.UIImage
import Foundation
import Then

final class DownloadableImageViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event.UI, Never>()

    init(url: URL) {
        self.state = State(
            status: .idle
        )

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(url: url)
            ]
        )
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}

extension DownloadableImageViewModel {
    func send(event: Event.UI) {
        input.send(event)
    }
}

extension DownloadableImageViewModel {
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
        }
    }
}

extension DownloadableImageViewModel {
    private static func whenLoading(url: URL) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .idle = state.status else { return Empty().eraseToAnyPublisher() }

            return URLSession.shared.dataTaskPublisher(for: url)
                .map { data, _ in UIImage(data: data) }
                .replaceError(with: nil)
                .map(Event.loaded)
                .eraseToAnyPublisher()
        }
    }
}

extension DownloadableImageViewModel {
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

        enum UI {
            case onAppear
            case onDisappear
        }
    }
}

extension DownloadableImageViewModel {
    static var placeholder: UIImage {
        UIImage(named: "thumbnail_mock")!
    }
}
