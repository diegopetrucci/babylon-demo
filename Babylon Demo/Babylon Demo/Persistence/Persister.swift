import Disk
import Combine

protocol PersisterProtocol {
    func retrieve<T: Decodable>(t: T.Type, path: String) -> AnyPublisher<T, PersistanceError>
    func persist<T: Encodable>(t: T, path: String) -> AnyPublisher<Void, PersistanceError>
}

struct Persister: PersisterProtocol {
    func retrieve<T: Decodable>(t: T.Type, path: String) -> AnyPublisher<T, PersistanceError> {
        do {
            let t = try Disk.retrieve(path, from: .caches, as: t.self)
            return Just(t)
                .setFailureType(to: PersistanceError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail<T, PersistanceError>(error: PersistanceError.failure(error))
                .eraseToAnyPublisher()
        }
    }

    func persist<T: Encodable>(t: T, path: String) -> AnyPublisher<Void, PersistanceError> {
        do {
            try Disk.save(t, to: .caches, as: path)
            return Just(())
                .setFailureType(to: PersistanceError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail<Void, PersistanceError>(error: PersistanceError.failure(error))
                .eraseToAnyPublisher()
        }
    }
}

enum PersistanceError: Error {
    case failure(Error)
}
