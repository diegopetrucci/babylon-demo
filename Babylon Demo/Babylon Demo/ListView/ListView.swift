import SwiftUI

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if viewModel.elements.isNotEmpty() {
                NavigationView {
                    Section {
                        List(viewModel.elements.filter { $0.isFavourite }.indices, id: \.self) { index in
                            ListCell(
                                title: self.viewModel.elements[index].title,
                                thumbnail: self.viewModel.thumbnails.first(where: { $0.id == self.viewModel.elements[index].id })
                            )
                                .onAppear(perform: { self.viewModel.onListCellAppear(index) })
                        }
                    }
                    List(viewModel.elements.sorted(by: viewModel.isSortedByFavourites).indices, id: \.self) { index in
                        // TODO make it injected
                        NavigationLink(destination: PhotoDetailView(
                            viewModel: self.viewModel(for: self.viewModel.elements[index])
                        )) {
                            ListCell(
                                title: self.viewModel.elements[index].title,
                                thumbnail: self.viewModel.thumbnails.first(where: { $0.id == self.viewModel.elements[index].id })
                            )
                                .onAppear(perform: { self.viewModel.onListCellAppear(index) })
                        }
                        .background(self.viewModel.elements[index].isFavourite ? Color.yellow : nil)
                    }
                    .navigationBarTitle("Photos")
                }
            } else {
                Text("Data has not loaded yet")
            }
        }
        .onAppear { self.viewModel.onAppear() }
    }
}

extension ListView {
    private func viewModel(for element: ListView.Element) -> PhotoDetailViewModel {
        .init(
            element: element,
            albumID: element.albumID,
            photoID: element.id,
            photoURL: element.photoURL,
            api: JSONPlaceholderAPI()
        )
    }
}

struct ListCell: View {
    let title: String
    let thumbnail: ListView.Thumbnail?

    var body: some View {
        HStack(spacing: 10) {
            thumbnailOrFallback(for: thumbnail)
            Text(title)
            Spacer()
        }
    }
}

extension ListCell {
    private func thumbnailOrFallback(for thumbnail: ListView.Thumbnail?) -> some View {
        Group {
            if thumbnail?.image != nil {
                Image(uiImage: thumbnail!.image!) // I should use my own if-let replacement here
                    .resizable()
                    .frame(
                        maxWidth: thumbnail!.size!.width,
                        maxHeight: thumbnail!.size!.height
                    )
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .frame(
                        width: 150,
                        height: 150
                )
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(viewModel: ListViewModel(api: APIFixture()))
    }
}
