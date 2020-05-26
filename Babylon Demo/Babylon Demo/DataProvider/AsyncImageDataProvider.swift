import Combine
import class UIKit.UIImage
import struct Foundation.URL
import class Foundation.URLSession
import Disk

protocol AsyncImageDataProviderProtocol {
    func fetchImage(url: URL) -> AnyPublisher<UIImage, AsyncImageDataProviderError>
    func persistImage(image: UIImage, url: URL) -> AnyPublisher<Void, Never>
}

struct AsyncImageDataProvider: AsyncImageDataProviderProtocol {
    private let api: API
    private let persister: ImagePersisterProtocol

    init(api: API, persister: ImagePersisterProtocol) {
        self.api = api
        self.persister = persister
    }
    
    func fetchImage(url: URL) -> AnyPublisher<UIImage, AsyncImageDataProviderError> {
        persister.fetch(path: url.absoluteString)
            .catch { _ in
                self.api.image(for: url)
                    .compactMap(identity) // TODO should the return type be an optional?
                    .mapError { AsyncImageDataProviderError.failure(RemoteError.error($0)) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func persistImage(image: UIImage, url: URL) -> AnyPublisher<Void, Never> {
        persister.persist(uiImage: image, path: url.absoluteString)
            .map { _ in }
            .replaceError(with: ())
            .eraseToAnyPublisher()
    }
}

enum AsyncImageDataProviderError: Error {
    case failure(RemoteError)
}

#if DEBUG
struct AsyncImageDataProviderFixture: AsyncImageDataProviderProtocol {
    func fetchImage(url: URL) -> AnyPublisher<UIImage, AsyncImageDataProviderError> {
        Just(UIImage.fixture())
            .setFailureType(to: AsyncImageDataProviderError.self)
            .eraseToAnyPublisher()
    }

    func persistImage(image: UIImage, url: URL) -> AnyPublisher<Void, Never> {
        Just(())
            .eraseToAnyPublisher()
    }
}
#endif

