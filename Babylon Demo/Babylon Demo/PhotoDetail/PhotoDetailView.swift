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
        if state.status == .idle {
            return AnyView(Text("Loading information, please wait…"))
        } else if state.status == .loading {
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
            return AnyView(
                VStack(spacing: 10) {
                    photo(with: state.photoDetail)
                    commentsView(numberOfComments: state.photoDetail.numberOfComments) // TODO this breaks the layout lol
                    Spacer()
                }
            )
        }
    }
}

// TODO This view needs to be broken up, it's unreadable
extension PhotoDetailView {
    private func photo(
        with photoDetail: PhotoDetailViewModel.PhotoDetail
    ) -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                viewModel.state.asyncImageView()
                HStack {
                    Text(photoDetail.title)
                        .foregroundColor(Color.white)
                        .font(.title)
                    Spacer()
                    Button(
                        action: { self.viewModel.send(event: .tappedFavouriteButton) },
                        label: { Text(photoDetail.isFavourite ? "★" : "☆"
                    )
                    .font(.largeTitle) }).padding()
                }
                    .padding()
            }
            authorView(name: photoDetail.author)
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
    
    private func commentsView(numberOfComments: Int) -> some View {
        HStack {
            Text("Number of comments: \(numberOfComments)")
                .padding()
            Spacer()
        }
    }
}

struct PhotoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoDetailView(viewModel: .fixture())
    }
}
