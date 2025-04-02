import SwiftUI

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    if userViewModel.isFetchingOfferings {
                        Text("Fetching offerings")
                    } else if let offerings = userViewModel.offerings {
                        ForEach(Array(offerings.all.values)) { offering in
                            Text(offering.identifier)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
            .task { await userViewModel.fetchOfferings() }
            .navigationTitle("Offerings")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { Task { await userViewModel.fetchOfferings() } }
        }
    }
}
