import SwiftUI

struct ListView: View {
    @Binding var elements: [Element]
    
    var body: some View {
//         TODO handle network errors
//        ForEach(elements, id: \.id) { element in
        List(elements, id: \.id) { element in
            HStack(spacing: 10) {
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
                Text(element.title)
                Spacer()
                Button(action: { element.with { $0.isFavourite.toggle() } }, label: { Text("Favourite") })
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
