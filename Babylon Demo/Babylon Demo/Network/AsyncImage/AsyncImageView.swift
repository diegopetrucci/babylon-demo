import SwiftUI

struct AsyncImageView: View {
    @ObservedObject var viewModel: AsyncImageViewModel

    var body: some View {
        // Note: I really did not want to use `AnyView` here,
        // as it's effectively an anti-pattern in SwiftUI,
        // but sadly just wrapping in `Group` is not working…
        Group<AnyView> {
            if case .loaded = viewModel.state.status {
                return AnyView(
                    Image(uiImage: viewModel.state.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                )
            } else {
                return AnyView(
                    Image(uiImage: AsyncImageViewModel.placeholder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                )
            }
        }
        .onAppear { self.viewModel.send(event: .onAppear) }
        .onDisappear { self.viewModel.send(event: .onDisappear) }
    }
}

struct AsyncImageView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncImageView(
            viewModel: .fixture()
        )
    }
}
