# babylon-demo
This app is meant to be an example of how "solve" [Babylon's demo project](https://github.com/babylonhealth/ios-playbook/blob/master/Interview/demo.md), written in SwiftUI &amp; Combine.

The architecture is MVVM, which I've found to fit quite nicely with the way SwiftUI works. Moreover, it follows the unidirectional data flows principles to make sure changes are always safe to perform and easy to understand. I've been using redux at work and in personal projects and I've found it to be very adaptable to most scenarios. It's not perfect, but these state machines definitely solve most problems of handling state.

I strongly believe in dependency injection. In this app, everything is injected and mocked/stubbed — or should, in theory. If I have missed something it's probably because I either have not noticed or not had the time to make it so. There are a few cases where DI in my opinion not the right way to go as it creates more problems that it solves, like global dependencies that do not hold complex state (e.g. branding colors), or static dependencies that again have no state.

### Low(er) hanging fruits
There are still quite a few things that I would like to address in future revisions.

Firstly, I dislike how SwiftUI harcodes navigation into views (i.e: `NavigationView` and `NavigationLink`), and have yet to find a satisfactory solution to inject them. The "usual" solution of using Coordinators seem to be slighly over-engineered for how simple SwiftUI makes everything else, so I chose not to go for it. Right now child views are built in View Models, which is equally ugly (a view model should not know anything about views). I'm probably going to end up injecting a closure into the view that constructs the desired child view, but I have not implemented it yet.

View Model and UI tests are missing. I consider the former more important, as a redux view model contains most of the view (and app!) logic, and so extensively testing it gives you the best bang for the buck. UI tests on the other hand, have been very unreliable in my experience: first they should not interface directly with the API/persistance, and second even given that they seem to be unreliable. I much prefer to have logic tested by view model tests + network/persistance unit tests, UI by snapshots, and very few core flows by UI tests. Exploratory testing by QA/product/engineers should take care of the remaining bugs.

The UI itself is lacking and unpolished. I consider myself an engineer with a strong eye (and opinions) on UI, and so not presenting this lackluster app makes my heart cry. Drama aside, the reason for this is that I envisioned this project as a pure iOS skills exercise, and considering even that part is not yet finished I had to make pragmatic choices.

There are a lot of `if #DEBUG`s scattered in the code. The sensible thing would be to move them to a different file belonging to the unit tests target, this is coming shortly. Another issue to be tackled soon are those that let SwiftUI previews mock the View Model's `init`s — the next step is to remove them and add a ViewModel protocol (or protocol witness, or whatever astraction suits it) to be able to mock them.

Adding some linter would be nice, too.

### External libraries
This project uses the Swift Package Manager to import third-party dependencies. I've found the SPM to be pretty easy to use, despite some quirks and limitations.

On to the libraries:

* *Then*: this is a micro-library that helps a lot with unidirectional data flow. It solves the problem of having to change just one (or a few) property in an object but not wanting to manually re-populate the entirety of the fields. This is especially useful when returning a new state, based on the previous one and an event, in the reducers.

* *Disk*: while networking, or at least what it's needed for this kind of project, is relative simple to write manually, I cannot say the same for writing to disk, as it is full of gotchas and edge cases. While this demo has quite a few unit and snapshot tests for it's core logic, I do not believe writing unit tests for the low-level intricacies of persisting to disk is a good use of time for the scope of the project. Hence, I've decided to use `Disk` to simplify this. In any case the persistance layer is abstracted by the various `DataProvider`s, so if need be we can move to different libraries.

* *SnapshotTesting*: this is [PointFree](https://github.com/pointfreeco/swift-snapshot-testing)'s snapshot testing library. I use it because it's simple and yet powerful enough for my needs. It currently does not support SwiftUI but it was quite simple to add that capability (see `SnapshotTesting+SwiftUI`)

### Known bugs and TODO's, in no particular order
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
* cancel network calls for images if the view didDisappear and it was not completed
* move integration tests to another target
