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
                        NavigationLink(
                            destination: self.viewModel.state.destination(for: index)
                        ) {
                            ListCell(
                                image: self.viewModel.state.asyncImageView(for: index),
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
