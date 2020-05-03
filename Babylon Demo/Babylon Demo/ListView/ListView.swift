import SwiftUI

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if viewModel.state.elements.isNotEmpty() {
                NavigationView {
                    Section {
                        List(viewModel.state.elements.filter { $0.isFavourite }.indices, id: \.self) { index in
                            ListCell(
                                title: self.viewModel.state.elements[index].title,
                                thumbnail: self.viewModel.state.thumbnails.first(where: { $0.id == self.viewModel.state.elements[index].id })
                            )
                                .onAppear(perform: { self.viewModel.send(.onListCellAppear(index)) })
                        }
                    }
                    // TODO the VM should sort them already
                    List(viewModel.state.elements.sorted(by: ListViewModel.isSortedByFavourites).indices, id: \.self) { index in
                        // TODO make it injected
                        NavigationLink(destination: PhotoDetailView(
                            viewModel: self.viewModel(for: self.viewModel.state.elements[index])
                        )) {
                            ListCell(
                                title: self.viewModel.state.elements[index].title,
                                thumbnail: self.viewModel.state.thumbnails.first(where: { $0.id == self.viewModel.state.elements[index].id })
                            )
                                .onAppear(perform: { self.viewModel.send(.onListCellAppear(index)) })
                        }
                        .background(self.viewModel.state.elements[index].isFavourite ? Color.yellow : nil)
                    }
                    .navigationBarTitle("Photos")
                }
            } else {
                Text("Data has not loaded yet")
            }
        }
        .onAppear { self.viewModel.send(.onAppear) }
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
