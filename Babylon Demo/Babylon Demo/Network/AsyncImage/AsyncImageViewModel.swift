import Combine
import class UIKit.UIImage
import Foundation
import Then
import Disk

final class AsyncImageViewModel: ObservableObject {
    @Published private(set) var state: State

    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event.UI, Never>()

    init(url: URL, imagePath: String) {
        self.state = State(
            status: .idle
        )

        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(url: url, imagePath: imagePath),
                Self.whenLoaded(imagePath: imagePath)
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
        }
    }
}

extension AsyncImageViewModel {
    private static func whenLoading(
        url: URL,
        imagePath: String
    ) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .idle = state.status else { return Empty().eraseToAnyPublisher() }

            // TODO: the VM should not directly call Disk, have a wrapper instead
            //       and maybe, even better, a DataProvider
            if let image = try? Disk.retrieve(imagePath, from: .caches, as: UIImage.self) {
                print("Image retrieved at path: \(imagePath)")
                return Just(Event.loaded(image))
                    .eraseToAnyPublisher()
            }

            return URLSession.shared.dataTaskPublisher(for: url)
                .map { data, _ in UIImage(data: data) }
                .replaceError(with: nil)
                .map(Event.loaded)
                .eraseToAnyPublisher()
        }
    }

    private static func whenLoaded(imagePath: String) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loaded(image) = state.status
            else {
                return Empty().eraseToAnyPublisher()
            }

            if (try? Disk.retrieve(imagePath, from: .caches, as: UIImage.self)) != nil {
                print("Image already present at path: \(imagePath)")
                return Empty().eraseToAnyPublisher()
            }

            if (try? Disk.save(image, to: .caches, as: imagePath)) != nil {
                print("Image saved at path: \(imagePath)")
            }

            return Empty().eraseToAnyPublisher()
        }
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

        enum UI {
            case onAppear
            case onDisappear
        }
    }
}

extension AsyncImageViewModel {
    static var placeholder: UIImage {
        UIImage(named: "thumbnail_mock")!
    }
}
