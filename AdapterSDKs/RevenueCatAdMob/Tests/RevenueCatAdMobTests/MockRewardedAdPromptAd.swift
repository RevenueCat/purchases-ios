import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatAdMob
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class MockRewardedAdPromptAd: RewardedAdPromptAd {

    let adUnitID = "supplied-ad-unit"
    weak var delegate: FullScreenContentDelegate?
    private(set) weak var presentingViewController: UIViewController?
    private(set) var enableVerificationCallCount = 0
    private(set) var disableVerificationCallCount = 0
    private(set) var isRewardVerificationEnabled = false
    private(set) var verificationEnabledPresentationCount = 0
    private(set) var verificationDisabledPresentationCount = 0
    private(set) var verificationStarted: (@MainActor () -> Void)?
    private(set) var verificationCompleted: (@MainActor (RewardVerificationResult) -> Void)?
    private(set) var rewardEarned: (() -> Void)?

    func setTrackingFullScreenContentDelegate(_ delegate: FullScreenContentDelegate?) {
        self.delegate = delegate
    }

    func enableRewardVerification() {
        self.enableVerificationCallCount += 1
        self.isRewardVerificationEnabled = true
    }

    func disableRewardVerification() {
        self.disableVerificationCallCount += 1
        self.isRewardVerificationEnabled = false
    }

    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        self.verificationEnabledPresentationCount += 1
        XCTAssertTrue(self.isRewardVerificationEnabled)
        self.presentingViewController = viewController
        self.verificationStarted = rewardVerificationStarted
        self.verificationCompleted = rewardVerificationCompleted
    }

    func present(
        from viewController: UIViewController?,
        userDidEarnRewardHandler: @escaping () -> Void
    ) {
        self.verificationDisabledPresentationCount += 1
        XCTAssertFalse(self.isRewardVerificationEnabled)
        self.presentingViewController = viewController
        self.rewardEarned = userDidEarnRewardHandler
    }

}

@available(iOS 15.0, *)
final class PresentedAdStub: NSObject, FullScreenPresentingAd {

    weak var fullScreenContentDelegate: FullScreenContentDelegate?

}
#endif
