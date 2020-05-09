struct Album {
    let userID: Int
}

extension Album: Decodable {
    enum CodingKeys: String, CodingKey {
        case userID = "userId"
    }
}

#if DEBUG
extension Album {
    static func fixture() -> Self {
        .init(userID: 36)
    }
}
#endif
