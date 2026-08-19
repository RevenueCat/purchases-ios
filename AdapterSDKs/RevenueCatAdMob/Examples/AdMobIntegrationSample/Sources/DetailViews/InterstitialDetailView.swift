import SwiftUI

struct InterstitialDetailView: View {

    @ObservedObject var manager: InterstitialAdManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Full-screen ad. Tracks Loaded, Displayed, Opened, and Revenue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                StatusAndButtons(
                    message: self.manager.message,
                    canShow: self.manager.canShow,
                    onLoad: { self.manager.loadAd() },
                    onShow: {
                        if let rootVC = RootViewController.current {
                            self.manager.showAd(from: rootVC)
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Interstitial Ad")
        .navigationBarTitleDisplayMode(.inline)
    }

}
