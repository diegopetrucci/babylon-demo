struct User {
    let id: Int
    let name: String
    let username: String
}

extension User: Decodable {}
extension User: Equatable {}

#if DEBUG
extension User {
    static func fixture(id: Int = 3) -> Self {
        .init(
            id: id,
            name: "Arthur Fonzarelli",
            username: "fonzie74"
        )
    }
}
#endif
