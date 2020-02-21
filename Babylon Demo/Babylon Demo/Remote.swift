import Foundation

protocol Remoteable {
    func load() -> Data
    func load<T>() -> T
}

final class Remote {
    private var dataTask: URLSessionDataTask? = nil
    
    func load(url: URL, completion: @escaping (Result<Data, RemoteError>) -> Void) {
        fetchData(url: url, dataTask: &dataTask, completion: completion)
    }
    
    func load<T: Decodable>(url: URL, completion: @escaping (Result<T, RemoteError>) -> Void) {
        fetchData(url: url, dataTask: &dataTask) { result in
            switch result {
            case let .success(data):
                let result: Result<T, RemoteError> = self.parse(data: data)
                switch result {
                case let .success(decoded):
                    completion(.success(decoded))
                case let .failure(error):
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

extension Remote {
    func fetchData(
        url: URL,
        dataTask: inout URLSessionDataTask?,
        completion: @escaping (Result<Data, RemoteError>) -> Void
    ) {
        dataTask = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(.failure(.error(error)))
                return
            }
            
            guard
                let data = data,
                let statusCode = (response as? HTTPURLResponse)?.statusCode
            else {
                    completion(.failure(.unknown))
                    return
            }
            
            guard statusCode == 200 else {
                completion(.failure(.statusCode(statusCode)))
                return
            }
            
            completion(.success(data))
        }
        
        dataTask?.resume()
    }
    
    func parse<T: Decodable>(data: Data) -> Result<T, RemoteError> {
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            return .success(result)
        } catch {
            return .failure(.parsingError(error))
        }
    }
}

enum RemoteError: Error {
    case error(Error)
    case statusCode(Int)
    case unknown
    case parsingError(Error)
}
