import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var viewModel: PhotoDetailViewModel
    
    var body: some View {
        render(state: viewModel.state)
            .onAppear { self.viewModel.send(event: .onAppear) }
    }
}

extension PhotoDetailView {
    private func render(state: PhotoDetailViewModel.State) -> some View {
        // TODO: is it possible to remove the wrapping into `AnyView`s?
        if state.status == .loading {
            return AnyView(Text("Loading information, please wait…"))
        } else if state.status == .notLoaded {
            // TODO add retry button
            return AnyView(Text("There was an error loading the image. Please go back and try again."))
        } else {
            // Ideally I would have a `switch` here, or at the very least an `if-let`
            // but at the moment SwiftUI does not support neither
            // e.g:
            // case let .loaded(title, image, author, numberOfComments, isFavourite)
            // So I had to resort to exposing these computed in the VM
            return AnyView(VStack(spacing: 10) {
                photo(with: state.props.0, state.props.1, state.props.2, state.props.3, state.props.4)
                commentsView(numberOfComments: state.props.3)
            })
        }
    }
}

// TODO This view needs to be broken up, it's unreadable
extension PhotoDetailView {
    private func photo(
        with title: String,
        _ image: UIImage,
        _ author: String?,
        _ numberOfComments: String?,
        _ isFavourite: Bool
        ) -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                HStack {
                    Text(title)
                        .foregroundColor(Color.white)
                        .font(.title)
                    Spacer()
                    Button(
                        action: { self.viewModel.send(event: .tappedFavouriteButton) },
                        label: { Text(isFavourite ? "★" : "☆"
                    )
                    .font(.largeTitle) }).padding()
                }
                .padding()
            }
            if author != nil {
                 authorView(name: author!) // TODO sigh…
            }
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
    
    private func commentsView(numberOfComments: String?) -> some View {
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
