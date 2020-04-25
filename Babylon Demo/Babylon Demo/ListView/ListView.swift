import SwiftUI

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if viewModel.elements.isNotEmpty() {
                NavigationView {
                    List(viewModel.elements.sorted(by: viewModel.isSortedByFavourites).indices, id: \.self) { index in
                        // TODO make it injected
                        NavigationLink(destination: PhotoDetailView(
                            viewModel: PhotoDetailViewModel(
                                element: self.viewModel.elements[index],
                                albumID: self.viewModel.elements[index].albumID,
                                photoID: self.viewModel.elements[index].id,
                                api: JSONPlaceholderAPI()
                            )
                        )) {
                            ListCell(
                                element: self.viewModel.elements[index],
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

struct ListCell: View {
    let element: ListView.Element
    let thumbnail: ListView.Thumbnail?

    var body: some View {
        HStack(spacing: 10) {
            thumbnailOrFallback(for: thumbnail)
            Text(element.title)
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
