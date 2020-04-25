import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var viewModel: PhotoDetailViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            photo()
            commentsView()
        }.onAppear { self.viewModel.onAppear() }
    }
}

// TODO This view needs to be broken up, it's unreadable
extension PhotoDetailView {
    private func photo() -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                imageOrFallback()
                HStack {
                    Text(viewModel.element.title)
                        .font(.title)
                    Spacer()
                    Button(
                        action: { self.viewModel.hasTappedFavouriteButton() },
                        label: { Text(self.viewModel.element.isFavourite ? "★" : "☆"
                    )
                    .font(.largeTitle) }).padding()
                }
                .padding()
            }
            authorView(name: viewModel.author)
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
            if viewModel.numberOfComments != nil {
                HStack {
                    Text("Number of comments: \(viewModel.numberOfComments!)") // Sigh…
                        .padding()
                    Spacer()
                }
            }
            Spacer()
        }
    }
}

extension PhotoDetailView {
    private func imageOrFallback() -> some View {
        Group {
            if viewModel.element.thumbnail?.image != nil {
                // sigh…
                Image(uiImage: viewModel.element.thumbnail!.image!)
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
            viewModel: PhotoDetailViewModel( // TODO make a fixture
                element: .fixture(),
                albumID: 1,
                photoID: 2,
                api: APIFixture()
            )
        )
    }
}
