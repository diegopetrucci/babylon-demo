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
                        idealWidth: element.thumbnail.size.width,
                        idealHeight: element.thumbnail.size.height
                    )
                Text(element.title)
                Spacer()
            }
        }
    }
}

extension ListView {
    struct Element: Identifiable {
        let id: Int
        let title: String
        let thumbnail: Thumbnail
    }
    
    struct Thumbnail {
        let image: UIImage
        let size: CGSize
    }
}


struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(elements: [.fixture(), .fixture(), .fixture()])
    }
}

#if DEBUG
extension ListView.Element {
    static func fixture() -> ListView.Element {
        .init(
            id: 47,
            title: "et soluta est",
            thumbnail: .init(
                image: UIImage(named: "thumbnail_mock")!,
                size: CGSize(width: 150, height: 150)
            )
        )
    }
}
#endif
