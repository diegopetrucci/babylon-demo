import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
            ListView(viewModel: viewModel)
    }
}

extension ContentView {
//    private func updateThumbnails(from photos: [Photo]) {
//        // We try to fetch the images at the top first
//        photos.sorted(by: { $0.id < $1.id }).forEach { photo in
//            // the poor man's pagination :D
//            guard photo.id < 100 else { return }
//
//            Remote().load(url: photo.thumbnailURL) { (result: Result<Data, RemoteError>) in
//                guard let index = self.elements.firstIndex(where: { $0.id == photo.id })  else { return }
//
//                guard case let .success(data) = result else { return }
//
//                DispatchQueue.main.async {
//                    print("changing image at index \(index)")
//                    self.elements[index].thumbnail.image = UIImage(data: data)
//                }
//            }
//        }
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            viewModel: ListViewModel(api: APIFixture())
        )
    }
}
