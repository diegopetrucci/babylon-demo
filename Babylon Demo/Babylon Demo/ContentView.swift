import SwiftUI

struct ContentView: View {
    // TODO @State
    let elements: [ListView.Element]?
    
    var body: some View {
        Group {
            // TODO if let having downloaded photos
            if elements != nil {
                ListView(elements: elements!)
            } else {
                Text("Data has not loaded yet")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(elements: [.fixture(), .fixture(), .fixture()])
    }
}
