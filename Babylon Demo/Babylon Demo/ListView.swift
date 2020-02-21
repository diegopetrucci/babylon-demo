import SwiftUI

struct ListView: View {
    // TODO @State
    let elements: [Element]
    
    var body: some View {
        // TODO handle network errors
        List(elements, id: \.id) { element in
            HStack(spacing: 10) {
                Image(uiImage: element.thumbnail.image)
                    .resizable()
                    .frame(
                        maxWidth: element.thumbnail.size.width,
                        maxHeight: element.thumbnail.size.height
                    )
                    .aspectRatio(contentMode: .fit)
                Text(element.title)
                Spacer()
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(elements: [.fixture(isFavourite: true), .fixture(), .fixture()])
    }
}
