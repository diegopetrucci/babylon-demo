import Disk
import Combine

protocol PersisterProtocol {
    func fetch<T: Codable>(type: T.Type, path: String) -> AnyPublisher<T, PersisterError>
    func persist<T: Codable>(t: T, path: String) -> AnyPublisher<PersistanceResult, PersisterError>
}

//struct Persisting<T: Codable> {
//    var fetch: (_ type: T.Type, _ path: String) -> AnyPublisher<T, Never>
//    var persist: (_ t: T, _ path: String) -> AnyPublisher<Void, Never>
//}

struct Persister: PersisterProtocol {
    func fetch<T: Codable>(type: T.Type, path: String) -> AnyPublisher<T, PersisterError> {
        do {
            let t = try Disk.retrieve(path, from: .caches, as: T.self)
            return Just(t)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail<T, PersisterError>(error: .error)
                .eraseToAnyPublisher()
        }
    }

    func persist<T: Codable>(t: T, path: String) -> AnyPublisher<PersistanceResult, PersisterError> {
        if (try? Disk.retrieve(path, from: .caches, as: T.self)) != nil {
            print("elements were already present, skipping persisting")
            return Just(.dataAlreadyPresent)
                .setFailureType(to: PersisterError.self)
                .eraseToAnyPublisher()
        }

        do {
            try Disk.save(t, to: .caches, as: path)
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

// This looks a bit odd (a `Result` that does not contain a `failure`?)
// But it's meant to represent the two "successful" states, by either
// having the data saved or not saved because it was already present.
// An error, eg if the operation to write to disk itself fails,
// is modelled in `PersisterError`

enum PersistanceResult {
    case persisted
    case dataAlreadyPresent
}

enum PersisterError: Error {
    case error
}
