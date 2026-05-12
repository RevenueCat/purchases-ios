import GoogleMobileAds
import SwiftUI

struct BannerAdView: UIViewRepresentable {

    let manager: BannerAdManager

    func makeUIView(context: Context) -> BannerView {
        return self.manager.loadAd()
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

}
