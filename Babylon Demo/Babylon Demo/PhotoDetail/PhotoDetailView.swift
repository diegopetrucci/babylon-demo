import SwiftUI

struct PhotoDetailView: View {
    @Binding var element: ListView.Element
    @State var author: String?
    @State var numberOfComments: String?
    
    var body: some View {
        VStack(spacing: 10) {
            photo()
            comments()
        }.onAppear { self.onAppear(photoID: self.element.id, albumID: self.element.albumID) }
    }
}

// This view needs to be broken up, it's unreadable
extension PhotoDetailView {
    private func photo() -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                imageOrFallback()
                HStack {
                    Text(element.title)
                        .font(.title)
                    Spacer()
                    Button(
                        action: { self.element.isFavourite.toggle() },
                        label: { Text(self.element.isFavourite ? "★" : "☆"
                    )
                    .font(.largeTitle) }).padding()
                }
                .padding()
            }
            if author != nil {
                HStack {
                    Spacer()
                    Text("A photo by \(author!)") // Sigh…
                        .padding()
                }
            }
        }
    }
    
    private func comments() -> some View {
        Group {
            if numberOfComments != nil {
                HStack {
                    Text("Number of comments: \(numberOfComments!)") // Sigh…
                        .padding()
                    Spacer()
                }
            }
            Spacer()
        }
    }
}

extension PhotoDetailView {
    private func onAppear(photoID: Int, albumID: Int) {
        DispatchQueue.global(qos: .background).async {
            Remote().load(
                url: URL(string: "http://jsonplaceholder.typicode.com/albums/\(albumID)")!) { (result: Result<Album, RemoteError>) in
                switch result {
                case let .success(album):
                    Remote().load(
                    url: URL(string: "http://jsonplaceholder.typicode.com/users/\(album.userID)")!) { (result: Result<User, RemoteError>) in
                        DispatchQueue.main.async {
                            switch result {
                            case let .success(user):
                                print(albumID)
                                print(album.userID)
                                print(user.name)
                                self.author = user.name
                            case let .failure(error):
                                self.author = nil
                            }
                        }
                    }
                case let .failure(error):
                    return
                }
            }
            
            Remote().load(
                url: URL(string: "https://jsonplaceholder.typicode.com/photos/\(photoID)/comments")!
            ) { (result: Result<Int, RemoteError>) in
                switch result {
                case let .success(numberOfComments):
                    self.numberOfComments = String(numberOfComments)
                case let .failure(error):
                    self.numberOfComments = nil
                }
            }
        }
    }
}

extension PhotoDetailView {
    private func imageOrFallback() -> some View {
        Group {
            if element.thumbnail.image != nil {
                // sigh…
                Image(uiImage: element .thumbnail.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
            }
        }
    }
}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(
            element: .constant(.fixture()),
            author: "someone",
            numberOfComments: "74"
        )
    }
}
