import Foundation
@_spi(Experimental) import RevenueCatAds
import UIKit

@MainActor
final class InterstitialAdManager: ObservableObject {

    @Published var apiKey = Constants.revenueCatAPIKey
    @Published var serverURL = Constants.serverURL
    @Published var placementID = Constants.placementID

    @Published private(set) var isLoading = false
    @Published private(set) var canShow = false
    @Published private(set) var isPresenting = false
    @Published private(set) var log: [String] = []

    private var interstitial: AdsInterstitial?

    init() {
        if Constants.autoRun {
            self.append("🤖 RC_ADS_AUTO_RUN: loading and presenting automatically")
            self.loadAndShowAd()
        }
    }

    func loadAndShowAd() {
        guard !self.isLoading, !self.isPresenting else { return }

        self.loadAd(presentingWhenLoaded: true)
    }

    func loadAd(presentingWhenLoaded: Bool = false) {
        guard let serverURL = URL(string: self.serverURL) else {
            self.append("❌ Invalid server URL: \(self.serverURL)")
            return
        }

        do {
            try RCAds.configure(with: AdsConfiguration(apiKey: self.apiKey, serverURL: serverURL))
        } catch {
            self.append("❌ Configure failed: \(error)")
            return
        }

        let interstitial = AdsInterstitial(placementID: self.placementID)
        interstitial.delegate = self
        self.interstitial = interstitial
        self.isLoading = true
        self.canShow = false
        self.append("⏳ Loading \(self.placementID) from \(serverURL)")

        Task {
            do {
                try await interstitial.load()
            } catch {
                print("❌ Interstitial load failed: \(error)")
            }
            self.isLoading = false
            self.canShow = interstitial.isReady
            if presentingWhenLoaded && self.canShow {
                self.showAd()
            }
        }
    }

    func showAd() {
        guard !self.isPresenting else { return }
        guard let interstitial = self.interstitial, let viewController = RootViewController.current else {
            self.append("⚠️ Nothing to present")
            return
        }

        self.isPresenting = true
        interstitial.present(from: viewController)
    }

    private func append(_ line: String) {
        print(line)
        self.log.insert(line, at: 0)
    }

}

extension InterstitialAdManager: AdsInterstitialDelegate {

    func interstitialDidLoad(_ interstitial: AdsInterstitial) {
        self.append("✅ Loaded")
    }

    func interstitial(_ interstitial: AdsInterstitial, didFailWithError error: AdsError) {
        self.isPresenting = false
        self.append("❌ Failed [\(error.code)]: \(error.message)")
        if let underlyingError = error.underlyingError {
            self.append("   ↳ \(underlyingError.localizedDescription)")
        }
    }

    func interstitialDidPresent(_ interstitial: AdsInterstitial) {
        self.canShow = false
        self.append("📺 Presented")
    }

    func interstitialDidRecordImpression(_ interstitial: AdsInterstitial) {
        self.append("👁️ Impression")
    }

    func interstitialDidRecordClick(_ interstitial: AdsInterstitial) {
        self.append("👆 Clicked")
    }

    func interstitialDidDismiss(_ interstitial: AdsInterstitial) {
        self.isPresenting = false
        self.append("👋 Dismissed")
    }

}
