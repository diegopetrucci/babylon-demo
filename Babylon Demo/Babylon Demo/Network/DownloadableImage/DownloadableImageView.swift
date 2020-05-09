import SwiftUI

struct DownloadableImageView: View {
    @ObservedObject var viewModel: DownloadableImageViewModel

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
                    Image(uiImage: DownloadableImageViewModel.placeholder)
                )
            }
        }
        .onAppear {
            self.viewModel.send(event: .onAppear) }
        .onDisappear { self.viewModel.send(event: .onDisappear) }
    }
}
