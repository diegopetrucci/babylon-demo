import Combine
import Foundation
import class UIKit.UIImage

final class PhotoDetailViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let api: API
    private let photoURL: URL

    let element: ListView.Element
    @Published private(set) var image: UIImage? = nil
    @Published private(set) var author: String? = nil
    @Published private(set) var numberOfComments: String? = nil

    init(
        element: ListView.Element,
        albumID: Int,
        photoID: Int,
        photoURL: URL,
        api: API = JSONPlaceholderAPI()
    ) {
        self.element = element
        self.api = api
        self.photoURL = photoURL

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
        guard let url = element.thumbnail?.url else { return }
        
        return api.image(for: url)
            .assign(to: \.image, on: self)
            .store(in: &cancellables)
    }

    func hasTappedFavouriteButton() {
        // TODO
//        self.element.isFavourite.toggle()
    }
}
