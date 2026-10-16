#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatAdMob
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
func makePromptLifecycleWindow(state: PromptLifecycleState, probe: PromptLifecycleProbe) -> UIWindow {
    let view = PromptLifecycleHost(state: state, probe: probe)
        .environment(\.rewardedAdPromptDependencies, probe.dependencies)
    return RewardedAdPromptTestWindow(rootViewController: UIHostingController(rootView: view))
}

@available(iOS 15.0, *)
@MainActor
final class PromptLifecycleState: ObservableObject {

    @Published var rewardedAd = LifecycleRewardedAd()
    @Published var interstitialAd = LifecycleRewardedInterstitialAd()
    @Published var isVisible = true
    @Published var label = "Offer"
    @Published var session: RewardedAdPromptSession?
    @Published var placement: String?
    @Published var resultLabel = "original"
    var usesVerification = false
    var usesInterstitial = false

    init(usesVerification: Bool = false) {
        self.usesVerification = usesVerification
        if usesVerification {
            RewardVerification.Setup.install(on: self.rewardedAd, token: .init(
                customData: "{}", clientTransactionID: "test-transaction", appUserID: "test-user"
            ))
        }
    }

}

@available(iOS 15.0, *)
@MainActor
final class PromptLifecycleProbe {

    var context: RewardedAdPromptContext?
    var renderedConfigurations: [ConfiguredAdRewards?] = []
    var lastLabel: String?
    var appearances = 0
    var disappearances = 0
    var shownCount = 0
    var acceptedCount = 0
    var shownPlacements: [String?] = []
    var acceptedPlacements: [String?] = []
    var cachedRewardsReadCount = 0
    var resultLabels: [String] = []
    var renderedResultLabel: String?
    var cachedRewards: () -> ConfiguredAdRewards? = { ConfiguredAdRewards() }

    var dependencies: RewardedAdPromptDependencies {
        .init(
            isPurchasesConfigured: { true },
            readCachedRewards: { _ in
                self.cachedRewardsReadCount += 1
                return self.cachedRewards()
            },
            trackPromptShown: { _, placement in
                self.shownCount += 1
                self.shownPlacements.append(placement)
            },
            trackPromptAccepted: { _, placement in
                self.acceptedCount += 1
                self.acceptedPlacements.append(placement)
            }
        )
    }

}

@available(iOS 15.0, *)
@MainActor
struct PromptLifecycleHost: View {

    @ObservedObject var state: PromptLifecycleState
    let probe: PromptLifecycleProbe

    var body: some View {
        let resultLabel = self.state.resultLabel
        Group {
            if self.state.isVisible {
                if self.state.usesVerification {
                    if self.state.usesInterstitial {
                        RewardedAdPrompt(
                            session: self.state.session, ad: self.state.interstitialAd,
                            placement: self.state.placement,
                            onResult: { _ in self.probe.resultLabels.append(resultLabel) }, content: self.content
                        )
                    } else {
                        RewardedAdPrompt(
                            session: self.state.session, ad: self.state.rewardedAd,
                            placement: self.state.placement,
                            onResult: { _ in self.probe.resultLabels.append(resultLabel) }, content: self.content
                        )
                    }
                } else {
                    if self.state.usesInterstitial {
                        RewardedAdPromptWithoutVerification(
                            session: self.state.session, ad: self.state.interstitialAd,
                            placement: self.state.placement,
                            onResult: { _ in self.probe.resultLabels.append(resultLabel) }, content: self.content
                        )
                    } else {
                        RewardedAdPromptWithoutVerification(
                            session: self.state.session, ad: self.state.rewardedAd,
                            placement: self.state.placement,
                            onResult: { _ in self.probe.resultLabels.append(resultLabel) }, content: self.content
                        )
                    }
                }
            }
        }
        .onAppear { self.probe.renderedResultLabel = resultLabel }
        .onChange(of: resultLabel) { self.probe.renderedResultLabel = $0 }
    }

    private func content(_ context: RewardedAdPromptContext) -> some View {
        self.probe.context = context
        self.probe.renderedConfigurations.append(context.rewardConfiguration)
        self.probe.lastLabel = self.state.label
        return Text(self.state.label)
            .onAppear { self.probe.appearances += 1 }
            .onDisappear { self.probe.disappearances += 1 }
    }

}

@available(iOS 15.0, *)
final class LifecycleRewardedAd: GoogleMobileAds.RewardedAd {

    override var adUnitID: String { "same-ad-unit" }
    private(set) var presentationCount = 0
    private(set) var rewardEarned: (() -> Void)?

    override func present(from viewController: UIViewController?, userDidEarnRewardHandler: @escaping () -> Void) {
        self.presentationCount += 1
        self.rewardEarned = userDidEarnRewardHandler
    }

}

@available(iOS 15.0, *)
final class LifecycleRewardedInterstitialAd: GoogleMobileAds.RewardedInterstitialAd {

    override var adUnitID: String { "same-ad-unit" }

}
#endif
