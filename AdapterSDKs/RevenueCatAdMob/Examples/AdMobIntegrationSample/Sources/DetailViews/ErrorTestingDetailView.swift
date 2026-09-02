import SwiftUI

struct ErrorTestingDetailView: View {

    @ObservedObject var manager: ErrorTestingAdManager
    @State private var showErrorFeedback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Uses an intentionally invalid ad unit ID to trigger and track load failures.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("Trigger Ad Load Error") {
                    self.manager.loadAd()
                    self.showErrorFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.showErrorFeedback = false
                    }
                }
                .buttonStyle(.bordered)

                if self.showErrorFeedback {
                    Text("Loading with invalid ID. Check console logs for failure tracking.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Error Testing")
        .navigationBarTitleDisplayMode(.inline)
    }

}
