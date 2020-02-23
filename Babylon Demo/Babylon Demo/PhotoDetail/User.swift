struct User {
    let id: Int
    let name: String
    let username: String
}

extension User: Decodable {}
