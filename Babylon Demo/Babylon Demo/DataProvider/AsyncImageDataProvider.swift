import Combine
import class UIKit.UIImage
import struct Foundation.URL
import class Foundation.URLSession
import Disk

protocol AsyncImageDataProviderProtocol {
    func fetchImage(url: URL, imagePath: String) -> AnyPublisher<UIImage, AsyncImageDataProviderError>
    func persistImage(image: UIImage, imagePath: String) -> AnyPublisher<Void, Never>
}

struct AsyncImageDataProvider: AsyncImageDataProviderProtocol {
    private let api: API

    init(api: API) {
        self.api = api
    }
    
    func fetchImage(url: URL, imagePath: String) -> AnyPublisher<UIImage, AsyncImageDataProviderError> {
        if let image = try? Disk.retrieve(imagePath, from: .caches, as: UIImage.self) {
            print("Image retrieved at path: \(imagePath)")

            return Just(image)
                .setFailureType(to: AsyncImageDataProviderError.self)
                .eraseToAnyPublisher()
        }

        return api.image(for: url)
            .compactMap { $0 } // TODO should the return type be an optional?
            .mapError { AsyncImageDataProviderError.failure(RemoteError.error($0)) }
            .eraseToAnyPublisher()
    }

    func persistImage(image: UIImage, imagePath: String) -> AnyPublisher<Void, Never> {
        if (try? Disk.retrieve(imagePath, from: .caches, as: UIImage.self)) != nil {
            print("Image already present at path: \(imagePath)")
            return Empty().eraseToAnyPublisher()
        }

        try? Disk.save(image, to: .caches, as: imagePath)
        print("Image saved at path: \(imagePath)")

        return Empty().eraseToAnyPublisher()
    }
}

enum AsyncImageDataProviderError: Error {
    case failure(RemoteError)
}

#if DEBUG
struct AsyncImageDataProviderFixture: AsyncImageDataProviderProtocol {
    func fetchImage(url: URL, imagePath: String) -> AnyPublisher<UIImage, AsyncImageDataProviderError> {
        Just(UIImage.fixture())
            .setFailureType(to: AsyncImageDataProviderError.self)
            .eraseToAnyPublisher()
    }

    func persistImage(image: UIImage, imagePath: String) -> AnyPublisher<Void, Never> {
        Just(())
            .eraseToAnyPublisher()
    }
}
#endif

