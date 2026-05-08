import SwiftUI

struct RewardedInterstitialDetailView: View {

    @ObservedObject var rewardedInterstitialAdManager: RewardedInterstitialAdManager
    @ObservedObject var verifiedRewardedInterstitialAdManager: VerifiedRewardedInterstitialAdManager

    @State private var usesRewardVerification = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Load with or without Reward Verification, then tap Show to present the loaded mode.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                RewardedControls(
                    message: self.message,
                    canShow: self.canShow,
                    usesRewardVerification: self.$usesRewardVerification,
                    onLoad: self.loadAd,
                    onShow: self.showAd
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Rewarded Interstitial Ad")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: self.usesRewardVerification) { _ in
            self.rewardedInterstitialAdManager.resetSelection()
            self.verifiedRewardedInterstitialAdManager.resetSelection()
        }
    }

    private var message: Message? {
        self.usesRewardVerification
            ? self.verifiedRewardedInterstitialAdManager.message
            : self.rewardedInterstitialAdManager.message
    }

    private var canShow: Bool {
        self.usesRewardVerification
            ? self.verifiedRewardedInterstitialAdManager.canShow
            : self.rewardedInterstitialAdManager.canShow
    }

    private func loadAd() {
        if self.usesRewardVerification {
            self.verifiedRewardedInterstitialAdManager.loadAd()
        } else {
            self.rewardedInterstitialAdManager.loadAd()
        }
    }

    private func showAd() {
        guard let rootVC = RootViewController.current else { return }
        if self.usesRewardVerification {
            self.verifiedRewardedInterstitialAdManager.showAd(from: rootVC)
        } else {
            self.rewardedInterstitialAdManager.showAd(from: rootVC)
        }
    }

}
