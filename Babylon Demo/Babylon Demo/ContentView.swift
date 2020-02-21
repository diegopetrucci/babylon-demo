import SwiftUI

struct ContentView: View {
    @State var elements: [ListView.Element]?
    @State private var favourites: [ListView.Element.ID] = [2, 4] // TODO remove harcoded
    
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
                self.elements = photos
                    .map(self.toElement)
                    .sorted(by: self.isFavourited)
            case let .failure(error): // TODO use error
                self.elements = nil
            }
        }
    }
    
    private func toElement(photo: Photo) ->  ListView.Element{
        .init(
            id: photo.id,
            title: photo.title,
            thumbnail: .init(
                image: UIImage(named: "thumbnail_mock")!, // TODO point of sync
                size: CGSize(width: 100, height: 100)
            ),
            isFavourite: self.favourites.contains(where: { photo.id == $0 })
        )
    }
    
    private func isFavourited(firstElement: ListView.Element, secondElement: ListView.Element) -> Bool {
        switch (firstElement.isFavourite, secondElement.isFavourite) {
        case (true, true), (false, false):
            return firstElement.id < secondElement.id
        case (true, false):
            return true
        case (false, true):
            return false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(elements: [.fixture(), .fixture(), .fixture()])
    }
}
