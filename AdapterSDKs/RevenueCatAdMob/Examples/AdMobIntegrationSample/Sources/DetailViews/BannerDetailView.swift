import SwiftUI

struct BannerDetailView: View {

    @ObservedObject var manager: BannerAdManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Always visible at the top. Tracks Loaded, Displayed, Opened, and Revenue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                BannerAdView(manager: self.manager)
                    .frame(height: 50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Banner Ad")
        .navigationBarTitleDisplayMode(.inline)
    }

}
