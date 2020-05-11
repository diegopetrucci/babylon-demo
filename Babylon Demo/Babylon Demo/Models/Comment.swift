struct Comment: Decodable {
    let postID: Int
    let id: Int
    let name: String
    let email: String
    let body: String


    enum CodingKeys: String, CodingKey {
        case postID = "postId"
        case id
        case name
        case email
        case body
    }
}

#if DEBUG
extension Comment {
    static func fixture() -> Comment {
        Comment(
            postID: 1,
            id: 2,
            name: "Mike Tyson",
            email: "mikey@tysonindustries.com",
            body: "That's a lovely photo"
        )
    }
}
#endif
