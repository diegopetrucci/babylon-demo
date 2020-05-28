import Disk
import Combine
import class SwiftUI.UIImage

protocol ImagePersisterProtocol {
    func fetch(path: String) -> AnyPublisher<UIImage, PersisterError>
    func persist(uiImage: UIImage, path: String) -> AnyPublisher<PersistanceResult, PersisterError>
}

struct ImagePersister: ImagePersisterProtocol {
    func fetch(path: String) -> AnyPublisher<UIImage, PersisterError> {
        do {
            let image = try Disk.retrieve(path, from: .caches, as: UIImage.self)
            return Just(image)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail<UIImage, PersisterError>(error: .error)
                .eraseToAnyPublisher()
        }
    }

    func persist(uiImage: UIImage, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        if (try? Disk.retrieve(path, from: .caches, as: UIImage.self)) != nil {
            print("elements were already present, skipping persisting")
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        do {
            try Disk.save(uiImage, to: .caches, as: path)
            print("Persisting elements")
            return Just((.persisted))
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        } catch {
            print("elements failed to persist")
            return Fail<PersistanceResult, PersisterError>(error: .error)
                .eraseToAnyPublisher()

        }
    }
}
