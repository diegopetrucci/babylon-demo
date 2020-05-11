import SwiftUI

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if viewModel.state.elements.isNotEmpty() {
                NavigationView {
                    // TODO the VM should sort them already
                    List(viewModel.state.elements.sorted(by: ListViewModel.isSortedByFavourites).indices, id: \.self) { index in
                        // TODO make it injected
                        NavigationLink(destination: PhotoDetailView(
                            viewModel: self.viewModel(for: self.viewModel.state.elements[index])
                        )) {
                            ListCell(
                                image: AsyncImageView(
                                    viewModel: AsyncImageViewModel( // TODO this should be injected
                                        url: self.viewModel.state.elements[index].thumbnailURL,
                                        imagePath: "/ListView/\(self.viewModel.state.elements[index].id)",
                                        dataProvider: AsyncImageDataProvider()
                                    )
                                ),
                                title: self.viewModel.state.elements[index].title
                            )
                        }
                        .background(self.viewModel.state.elements[index].isFavourite ? Color.yellow : nil)
                    }
                    .navigationBarTitle("Photos")
                }
            } else {
                Text("Data has not loaded yet")
            }
        }
    }
}

extension ListView {
    private func viewModel(for element: ListView.Element) -> PhotoDetailViewModel {
        .init(
            element: element,
            albumID: element.albumID,
            photoID: element.id,
            photoURL: element.thumbnailURL,
            api: JSONPlaceholderAPI()
        )
    }
}

struct ListCell: View {
    let image: AsyncImageView
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            image
                .frame(idealWidth: 150, idealHeight: 150)
            Text(title)
            Spacer()
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(viewModel: .fixture())
    }
}
