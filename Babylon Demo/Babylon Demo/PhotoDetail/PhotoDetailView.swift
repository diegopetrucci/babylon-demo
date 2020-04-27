import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var viewModel: PhotoDetailViewModel
    
    var body: some View {
        Group {
            // It's a shame SwiftUI does not support `switch`es yet.
            if viewModel.state.status == .loading {
                Text("Loading information, please wait…")
            } else if viewModel.state.status == .loaded {
                if viewModel.state.image != nil {
                    VStack(spacing: 10) {
                        photo()
                        commentsView()
                    }
                } else if viewModel.state.status == .notLoaded {
                    Text("There was an error loading the image.")
                }
            }
        }
        .onAppear { self.viewModel.send(event: .onAppear) }
    }
}

// TODO This view needs to be broken up, it's unreadable
extension PhotoDetailView {
    private func photo() -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                // TODO if no image is loaded it does not really make sense
                // to show title/author/comments either, so this logic should change
                if viewModel.state.image != nil {
                    // sigh…
                    Image(uiImage: viewModel.state.image!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                HStack {
                    Text(viewModel.state.title)
                        .foregroundColor(Color.white)
                        .font(.title)
                    Spacer()
                    Button(
                        action: { self.viewModel.send(event: .tappedFavouriteButton) },
                        label: { Text(self.viewModel.state.isFavourite ? "★" : "☆"
                    )
                    .font(.largeTitle) }).padding()
                }
                .padding()
            }
            authorView(name: viewModel.state.author)
        }
    }

    private func authorView(name: String?) -> some View {
        Group {
            if name != nil {
                HStack {
                    Spacer()
                    Text("A photo by \(name!)") // Sigh…
                        .padding()
                }
            }
        }
    }
    
    private func commentsView() -> some View {
        Group {
            if viewModel.state.numberOfComments != nil {
                HStack {
                    Text("Number of comments: \(viewModel.state.numberOfComments!)") // Sigh…
                        .padding()
                    Spacer()
                }
            }
            Spacer()
        }
    }
}

// This does not work, as it does not propagate
// the changes of self.image :/

//extension PhotoDetailView {
//    private func imageOrFallback() -> some View {
//        Group {
//            if viewModel.image != nil {
//                // sigh…
//                Image(uiImage: viewModel.image!)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//            } else {
//                Rectangle()
//                    .foregroundColor(Color.green)
//                    .frame(
//                        width: viewModel.image?.size.width ?? UIScreen.main.bounds.width,
//                        height: viewModel.image?.size.height ?? 400
//                )
//                    .aspectRatio(contentMode: .fit)
//            }
//        }
//    }
//}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(
            viewModel: PhotoDetailViewModel( // TODO make a fixture
                element: .fixture(),
                albumID: 1,
                photoID: 2,
                photoURL: URL(string: "http://google.com")!,
                api: APIFixture()
            )
        )
    }
}
