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
                photo(with: state.props.0, state.photoURL, state.props.1, state.props.2, state.props.3)
                commentsView(numberOfComments: state.props.2)
            })
        }
    }
}

// TODO This view needs to be broken up, it's unreadable
extension PhotoDetailView {
    private func photo(
        with title: String,
        _ photoURL: URL,
        _ author: String?,
        _ numberOfComments: String?,
        _ isFavourite: Bool
    ) -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                AsyncImageView(
                    viewModel: .init(
                        url: photoURL,
                        imagePath: "/PhotoDetail/\(viewModel.state.photoID)"
                    )
                ) // TODO
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

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(viewModel: .fixture())
    }
}
