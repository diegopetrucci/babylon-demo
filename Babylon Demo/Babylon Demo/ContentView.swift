import SwiftUI

struct ContentView: View {
    let url: URL
    
    @State var elements: [ListView.Element]
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if elements.isNotEmpty() {
                ListView(elements: $elements)
            } else {
                Text("Data has not loaded yet")
            }
        }.onAppear { self.onAppear() }
    }
}

extension ContentView {
    private func onAppear() {
        DispatchQueue.global(qos: .background).async {
            Remote().load(
            url: self.url) { (result: Result<[Photo], RemoteError>) in
                switch result {
                case let .success(photos):
                    DispatchQueue.main.async {
                        self.elements = photos
                            .map(toElement)
                            .sorted(by: isSortedByFavourites)
                    }
                    
                    self.updateThumbnails(from: photos)
                case let .failure(error): // TODO use error
                    DispatchQueue.main.async {
                        self.elements = []
                    }
                }
            }
        }
    }
    
    private func updateThumbnails(from photos: [Photo]) {
        // We try to fetch the images at the top first
        photos.sorted(by: { $0.id < $1.id }).forEach { photo in
            // the poor man's pagination :D
            guard photo.id < 100 else { return }
            
            Remote().load(url: photo.thumbnailURL) { (result: Result<Data, RemoteError>) in
                guard let index = self.elements.firstIndex(where: { $0.id == photo.id })  else { return }
                
                guard case let .success(data) = result else { return }
                
                DispatchQueue.main.async {
                    print("changing image at index \(index)")
                    self.elements[index].thumbnail.image = UIImage(data: data)
                }
            }
        }
    }
}
    
private func toElement(photo: Photo) -> ListView.Element {
    .init(
        id: photo.id,
        title: photo.title,
        thumbnail: .init(
            image: UIImage(named: "thumbnail_mock")!, // TODO point of sync
            size: CGSize(width: 100, height: 100)
        ),
        isFavourite: false
    )
}

func isSortedByFavourites(firstElement: ListView.Element, secondElement: ListView.Element) -> Bool {
    switch (firstElement.isFavourite, secondElement.isFavourite) {
    case (true, true), (false, false):
        return firstElement.id < secondElement.id
    case (true, false):
        return true
    case (false, true):
        return false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            url: URL(string: "http://jsonplaceholder.typicode.com/photos")!,
            elements: [.fixture(), .fixture(), .fixture()]
        )
    }
}
