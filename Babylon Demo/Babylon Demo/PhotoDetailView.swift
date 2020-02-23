import SwiftUI

struct PhotoDetailView: View {
    @Binding var element: ListView.Element
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                imageOrFallback()
                HStack {
                    Text(element.title)
                    Spacer()
                    Button(action: { self.element.isFavourite.toggle() }, label: { Text("Favourite") })
                }
                .padding()
            }
            HStack {
                Spacer()
                Text("A photo by $$$") // TODO author
                    .padding()
            }
            Spacer()
        }
    }
}

extension PhotoDetailView {
    private func imageOrFallback() -> some View {
        Group {
            if element.thumbnail.image != nil {
                // sigh…
                Image(uiImage: element .thumbnail.image!)
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
        PhotoDetailView(element: .constant(.fixture()))
    }
}
