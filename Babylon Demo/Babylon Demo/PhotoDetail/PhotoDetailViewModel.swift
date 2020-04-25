import Combine
import Foundation

final class PhotoDetailViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    let element: ListView.Element
    @Published private(set) var author: String? = nil
    @Published private(set) var numberOfComments: String? = nil

    init(element: ListView.Element, albumID: Int, photoID: Int, api: API) {
        self.element = element

        api.album(with: albumID)
            .flatMap { api.user(with: $0.userID) }
            .map { $0.name }
            .replaceError(with: nil)
            .assign(to: \.author, on: self)
            .store(in: &cancellables)

        api.numberOfComments(for: photoID)
            .map(String.init)
            .replaceError(with: nil)
            .assign(to: \.numberOfComments, on: self)
            .store(in: &cancellables)
    }

    func onAppear() {
        // TODO
    }

    func hasTappedFavouriteButton() {
        // TODO
//        self.element.isFavourite.toggle()
    }
}
