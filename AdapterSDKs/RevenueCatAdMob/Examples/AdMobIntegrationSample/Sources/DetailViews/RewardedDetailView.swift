import SwiftUI

struct RewardedDetailView: View {

    @ObservedObject var rewardedAdManager: RewardedAdManager
    @ObservedObject var verifiedRewardedAdManager: VerifiedRewardedAdManager

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
        .navigationTitle("Rewarded Ad")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: self.usesRewardVerification) { _ in
            self.rewardedAdManager.resetSelection()
            self.verifiedRewardedAdManager.resetSelection()
        }
    }

    private var message: String {
        self.usesRewardVerification
            ? self.verifiedRewardedAdManager.message
            : self.rewardedAdManager.message
    }

    private var canShow: Bool {
        self.usesRewardVerification
            ? self.verifiedRewardedAdManager.canShow
            : self.rewardedAdManager.canShow
    }

    private func loadAd() {
        if self.usesRewardVerification {
            self.verifiedRewardedAdManager.loadAd()
        } else {
            self.rewardedAdManager.loadAd()
        }
    }

    private func showAd() {
        guard let rootVC = RootViewController.current else { return }
        if self.usesRewardVerification {
            self.verifiedRewardedAdManager.showAd(from: rootVC)
        } else {
            self.rewardedAdManager.showAd(from: rootVC)
        }
    }

}
