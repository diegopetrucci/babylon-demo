import SwiftUI

struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        render(viewModel.state)
    }

    private func render(_ state: ListViewModel.State) -> some View {
        // TODO: is it possible to remove the wrapping into `AnyView`s?
        if state.status == .loading {
            return AnyView(Text("Loading information, please wait…"))
        } else if state.status == .error { // TODO either `error` or `notLoaded` (like PhotoDetailVM)
            // TODO add retry button
            return AnyView(Text("There was an error loading the image. Please go back and try again."))
        } else {
            // Ideally I would have a `switch` here, or at the very least an `if-let`
            // but at the moment SwiftUI does not support either
            // e.g:
            // case let .loaded(title, image, author, numberOfComments, isFavourite)
            // So I had to resort to exposing these computed in the VM
            return AnyView(listView())
        }
    }

    private func listView() -> some View {
        NavigationView {
            // TODO the VM should sort them already?
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
