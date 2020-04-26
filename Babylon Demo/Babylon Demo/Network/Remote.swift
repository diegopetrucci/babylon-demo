import Foundation
import Combine
import class UIKit.UIImage

protocol Remoteable {
    func load<T: Decodable>(from url: URL, jsonDecoder: JSONDecoder) -> AnyPublisher<T, RemoteError>
    func loadData(from imageURL: URL) -> AnyPublisher<Data, RemoteError>
}

struct Remote: Remoteable {
    func load<T: Decodable>(
        from url: URL,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> AnyPublisher<T, RemoteError> {
        URLSession.shared.dataTaskPublisher(for: URLRequest(url: url))
            .mapError(RemoteError.error)
            .tryMap(validStatusCode)
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError(RemoteError.parsingError)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func loadData(from imageURL: URL) -> AnyPublisher<Data, RemoteError> {
        URLSession.shared.dataTaskPublisher(for: URLRequest(url: imageURL))
            .mapError(RemoteError.error)
            .tryMap(validStatusCode)
            // ugh
            .mapError { error in
                if let error = error as? RemoteError {
                    return error
                } else {
                    return RemoteError.unknown
                }
        }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension Remote {
    private func validStatusCode(data: Data, response: URLResponse) throws -> Data {
        guard
            let statusCode = (response as? HTTPURLResponse)?.statusCode
        else { throw RemoteError.unknown }

        guard
            statusCode >= 200,
            statusCode < 300
        else { throw RemoteError.statusCode(statusCode) }

        return data
    }
}

enum RemoteError: Error {
    case error(Error)
    case statusCode(Int)
    case unknown
    case parsingError(Error)
    case malformedImage
}
