# babylon-demo
This app is meant to be an example of how "solve" Babylon's demo project, written in SwiftUI &amp; Combine.

The architecture is MVVM, which I've found to fit quite nicely with the way SwiftUI works. Moreover, it follows the unidirectional data flows principles to make sure changes are always safe to perform and easy to understand.

### External libraries
This project uses the Swift Package Manager to import third-party dependencies. I've found the SPM to be pretty easy to use, despite some quirks and limitations.

On to the libraries:

* *Then*: this is a micro-library that helps a lot with unidirectional data flow. It solves the problem of having to change just one (or a few) property in an object but not wanting to manually re-populate the entirety of the fields. This is especially useful when returning a new state, based on the previous one and an event, in the reducers.

* *Disk*: while networking, or at least what it's needed for this kind of project, is relative simple to write manually, I cannot say the same for writing to disk, as it is full of gotchas and edge cases. While this demo has quite a few unit and snapshot tests for it's core logic, I do not believe writing unit tests for the low-level intricacies of persisting to disk is a good use of time for the scope of the project. Hence, I've decided to use `Disk` to simplify this. In any case the persistance layer is abstracted by the various `DataProvider`s, so if need be we can move to different libraries.

* *SnapshotTesting*: this is [PointFree](https://github.com/pointfreeco/swift-snapshot-testing)'s snapshot testing library. I use it because it's simple and yet powerful enough for my needs. It currently does not support SwiftUI but it was quite simple to add that capability (see `SnapshotTesting+SwiftUI`)



### To explain
* if debug

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
* add snapshot tests
* add unit tests
* make sure accessibility is good
* write to disk
* create a feedback initializers that lenses the state's status
* add reachability