import SwiftUI

struct OfferingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    Text("Hello World")
                }
            }
        }
        .navigationTitle("Offerings")
        .navigationBarTitleDisplayMode(.large)
    }
}
