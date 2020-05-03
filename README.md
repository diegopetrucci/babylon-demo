# babylon-demo
Babylon demo project in SwiftUI &amp; Combine

### Known bugs and TODO's
* Add pagination
* Marking a photo as favourite does not make it appear at the top in the photos list
* network call should be prioritized/paginated/cancelled: loading data of a photo down the list takes a while
* As you scroll futher and further not all thumbnails are downloaded
* Visually separate favourites and non with sections
* Favourites at the top
* download thumbnails
* set a max size for photos in detail view
* thumbnails don't seem to update with the correct image if the photodetail view is entered while thumbnail is still loading
* add a way to mock the state in VMs otherwise they all start with the initial status, making the preview useless