import SwiftUI

struct ListView: View {
    @Binding var elements: [Element]
    
    var body: some View {
        NavigationView {
            List(elements.sorted(by: isSortedByFavourites).indices, id: \.self) { index in
//                Section(header: Text("Favourites")) {
                    NavigationLink(destination: PhotoDetailView(element: self.$elements[index])) {
                        HStack(spacing: 10) {
                            self.thumbnailOrFallback(for: self.elements[index])
                            Text(self.elements[index].title)
                            Spacer()
                        }
                    }.background(self.elements[index].isFavourite ? Color.yellow : nil )
//                }
            }
            .navigationBarTitle("Photos")
        }
    }
}

extension ListView {
    private func thumbnailOrFallback(for element: Element) -> some View {
        Group {
            if element.thumbnail.image != nil {
                Image(uiImage: element.thumbnail.image!) // I should use my own if-let replacement here
                    .resizable()
                    .frame(
                        maxWidth: element.thumbnail.size.width,
                        maxHeight: element.thumbnail.size.height
                    )
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .frame(
                        width: element.thumbnail.size.width,
                        height: element.thumbnail.size.height
                )
            }
        }
    }
}

extension ListView {
    private func toggleFavourite(for element: Element) {
        element.with { $0.isFavourite.toggle() }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(elements: .constant([.fixture(isFavourite: true), .fixture(), .fixture()]))
    }
}
