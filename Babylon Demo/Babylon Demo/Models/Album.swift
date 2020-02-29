struct Album {
    let userID: Int
}

extension Album: Decodable {
    enum CodingKeys: String, CodingKey {
        case userID = "userId"
    }
}
