import struct Foundation.URL

#if DEBUG
extension URL {
    static func fixture() -> URL {
        URL(string: "http://google.com")!
    }
}
#endif
