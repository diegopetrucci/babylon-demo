import SwiftUI

struct ContentView: View {
    @State var elements: [ListView.Element]?
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if elements != nil {
                ListView(elements: elements!)
            } else {
                Text("Data has not loaded yet")
            }
        }.onAppear { self.onAppear() }
    }
}

extension ContentView {
    private func onAppear() {
        Remote().load(
        url: URL(string: "http://jsonplaceholder.typicode.com/photos")!) { (result: Result<[Photo], RemoteError>) in
            switch result {
            case let .success(photos):
                self.elements = photos.map {
                    ListView.Element(
                        id: $0.id,
                        title: $0.title,
                        thumbnail: .init(
                            image: UIImage(named: "thumbnail_mock")!, // TODO point of sync
                            size: CGSize(width: 100, height: 100)
                        )
                    )
                }
            case let .failure(error): // TODO use error
                self.elements = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(elements: [.fixture(), .fixture(), .fixture()])
    }
}

struct Photo {
    let id: Int
    let title: String
    let url: URL
    let thumbnailURL: URL
}

extension Photo: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case thumbnailURL = "thumbnailUrl"
    }
}
