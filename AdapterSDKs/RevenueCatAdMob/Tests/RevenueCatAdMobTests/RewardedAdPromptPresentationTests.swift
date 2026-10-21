import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptPresentationTests: AdapterTestCase {

    func testUnattachedAnchorDoesNotResolvePresentationController() {
        let anchor = UIViewController()
        let parent = UIViewController()
        parent.addChild(anchor)
        parent.view.addSubview(anchor.view)
        anchor.didMove(toParent: parent)

        XCTAssertNil(anchor.rewardedAdPromptPresentationViewController)
    }

    func testResolvesVisibleNavigationController() {
        let anchor = UIViewController()
        let navigation = UINavigationController(rootViewController: anchor)
        let window = RewardedAdPromptTestWindow(rootViewController: navigation)
        defer { window.isHidden = true }

        XCTAssertTrue(anchor.rewardedAdPromptPresentationViewController === anchor)
    }

    func testResolvesSelectedTabAndNavigationController() {
        let anchor = UIViewController()
        let tabs = UITabBarController()
        tabs.viewControllers = [UIViewController(), UINavigationController(rootViewController: anchor)]
        tabs.selectedIndex = 1
        let window = RewardedAdPromptTestWindow(rootViewController: tabs)
        defer { window.isHidden = true }

        XCTAssertTrue(anchor.rewardedAdPromptPresentationViewController === anchor)
    }

    func testResolvesSecondarySplitController() {
        let anchor = UIViewController()
        let split = UISplitViewController()
        split.viewControllers = [UIViewController(), anchor]
        let window = RewardedAdPromptTestWindow(rootViewController: split)
        defer { window.isHidden = true }

        XCTAssertTrue(anchor.rewardedAdPromptPresentationViewController === anchor)
    }

    func testUsesAnchorsWindowInsteadOfAnotherKeyWindow() {
        let anchor = UIViewController()
        let window = RewardedAdPromptTestWindow(rootViewController: anchor)
        let otherWindow = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        otherWindow.makeKey()
        defer {
            otherWindow.isHidden = true
            window.isHidden = true
        }

        XCTAssertTrue(anchor.rewardedAdPromptPresentationViewController === anchor)
    }

    func testAcceptanceResolvesCurrentModalPresenter() throws {
        let anchor = RewardedAdPromptPresentationRoot()
        let window = RewardedAdPromptTestWindow(rootViewController: anchor)
        defer { window.isHidden = true }
        let rewardedAd = MockRewardedAdPromptAd()
        let model = self.makeModel(ad: rewardedAd, callbackDispatcherFactory: {
            makeUnverifiedPromptCallbacks(onPresentationFailed: { _ in XCTFail("Presentation should succeed") })
        })
        model.setPresentationAnchor(anchor)
        let modal = UIViewController()
        anchor.view.addSubview(modal.view)
        anchor.currentPresentedViewController = modal

        try XCTUnwrap(model.context).accept()

        XCTAssertTrue(rewardedAd.presentingViewController === modal)
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 1)
    }

    func testRejectsDetachedModalPresenter() {
        let anchor = RewardedAdPromptPresentationRoot()
        let window = RewardedAdPromptTestWindow(rootViewController: anchor)
        defer { window.isHidden = true }
        anchor.currentPresentedViewController = UIViewController()

        XCTAssertNil(anchor.rewardedAdPromptPresentationViewController)
    }

    func testMissingAnchorReportsNotPresentedOnceForBothModes() async throws {
        for verified in [true, false] {
            try await self.assertNotPresented(verified: verified, anchor: nil)
        }
    }

    func testDismissalIsDeliveredThroughSuppliedAdDelegate() throws {
        let rewardedAd = MockRewardedAdPromptAd()
        var dismissalCount = 0
        let model = self.makeModel(ad: rewardedAd, callbackDispatcherFactory: {
            makeUnverifiedPromptCallbacks(onDismiss: { dismissalCount += 1 })
        })
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        try XCTUnwrap(model.context).accept()

        rewardedAd.delegate?.adDidDismissFullScreenContent?(PresentedAdStub())

        XCTAssertEqual(dismissalCount, 1)
    }

    func testCallbacksSurviveModelReleaseBeforeOrAfterDismissalForBothModes() throws {
        for verified in [false, true] {
            for rewardFinishesFirst in [false, true] {
                let rewardedAd = MockRewardedAdPromptAd()
                var rewardCount = 0
                var dismissalCount = 0
                let onDismiss: @MainActor () -> Void = { dismissalCount += 1 }
                var model: RewardedAdPromptModel? = self.makeModel(ad: rewardedAd, callbackDispatcherFactory: {
                    if verified {
                        return makeVerifiedPromptCallbacks(onVerificationCompleted: { result in
                            XCTAssertEqual(result, .verified(.noReward))
                            rewardCount += 1
                        }, onDismiss: onDismiss)
                    } else {
                        return makeUnverifiedPromptCallbacks(onRewardEarned: {
                            rewardCount += 1
                        }, onDismiss: onDismiss)
                    }
                })
                let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
                defer { window.isHidden = true }
                model?.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
                try XCTUnwrap(model?.context).accept()
                weak var releasedModel = model
                model = nil
                XCTAssertNil(releasedModel)

                let earnReward = {
                    rewardedAd.rewardEarned?()
                    rewardedAd.verificationCompleted?(.verified(.noReward))
                }
                if rewardFinishesFirst { earnReward() }
                XCTAssertEqual(rewardCount, rewardFinishesFirst ? 1 : 0)
                XCTAssertEqual(dismissalCount, 0)

                let delegate = try XCTUnwrap(rewardedAd.delegate)
                delegate.adDidDismissFullScreenContent?(PresentedAdStub())
                XCTAssertEqual(dismissalCount, 1)
                XCTAssertEqual(rewardCount, rewardFinishesFirst ? 1 : 0)
                if !rewardFinishesFirst { earnReward() }
                earnReward()
                delegate.adDidDismissFullScreenContent?(PresentedAdStub())
                XCTAssertEqual(rewardCount, 1)
                XCTAssertEqual(dismissalCount, 1)
            }
        }
    }

    func testDetachedAnchorReportsNotPresentedOnceForBothModes() async throws {
        for verified in [true, false] {
            try await self.assertNotPresented(verified: verified, anchor: UIViewController())
        }
    }

    func testAnchorDetachedAfterResolutionReportsNotPresentedForBothModes() async throws {
        for verified in [true, false] {
            let anchor = UIViewController()
            let window = RewardedAdPromptTestWindow(rootViewController: anchor)
            defer { window.isHidden = true }
            XCTAssertNotNil(anchor.rewardedAdPromptPresentationViewController)

            try await self.assertNotPresented(verified: verified, anchor: anchor) {
                window.rootViewController = UIViewController()
            }
        }
    }

}

@available(iOS 15.0, *)
@MainActor
private extension RewardedAdPromptPresentationTests {

    func assertNotPresented(
        verified: Bool,
        anchor: UIViewController?,
        beforeAcceptance: () -> Void = {}
    ) async throws {
        let delivered = self.expectation(description: "Presentation failure delivered")
        let rewardedAd = MockRewardedAdPromptAd()
        var errors: [RewardedAdPromptError] = []
        var acceptanceCount = 0
        let onFailure: @MainActor (RewardedAdPromptError) -> Void = {
            errors.append($0)
            delivered.fulfill()
        }
        let model = self.makeModel(ad: rewardedAd, callbackDispatcherFactory: {
            if verified {
                return makeVerifiedPromptCallbacks(onPresentationFailed: onFailure)
            } else {
                return makeUnverifiedPromptCallbacks(onPresentationFailed: onFailure)
            }
        }, trackAccepted: { acceptanceCount += 1 })
        if let anchor { model.setPresentationAnchor(anchor) }
        let context = try XCTUnwrap(model.context)
        beforeAcceptance()

        context.accept()
        context.accept()

        XCTAssertTrue(errors.isEmpty)
        await self.fulfillment(of: [delivered], timeout: 1)

        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors.first?.code, .presentationContextUnavailable)
        XCTAssertNil(errors.first?.underlyingError)
        XCTAssertEqual(acceptanceCount, 1)
        XCTAssertTrue(model.hasAccepted)
        XCTAssertNil(model.context)
        XCTAssertNil(rewardedAd.delegate)
        XCTAssertEqual(rewardedAd.enableVerificationCallCount, 0)
        XCTAssertEqual(rewardedAd.disableVerificationCallCount, 0)
        XCTAssertEqual(rewardedAd.verificationEnabledPresentationCount, 0)
        XCTAssertEqual(rewardedAd.verificationDisabledPresentationCount, 0)
    }

    func makeModel(
        ad rewardedAd: MockRewardedAdPromptAd,
        callbackDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptCallbackDispatching,
        trackAccepted: @escaping () -> Void = {}
    ) -> RewardedAdPromptModel {
        return .init(
            session: RewardedAdPromptSession(),
            ad: rewardedAd,
            placement: nil,
            loadsRewardConfiguration: false,
            callbackDispatcherFactory: callbackDispatcherFactory,
            dependencies: .init(
                isPurchasesConfigured: { true },
                loadRewards: { _ in nil },
                trackPromptShown: { _, _ in },
                trackPromptAccepted: { _, _ in trackAccepted() }
            )
        )
    }

}

// Hostless package tests cannot drive modal transitions, so supply the presented controller directly.
@MainActor
private final class RewardedAdPromptPresentationRoot: UIViewController {

    var currentPresentedViewController: UIViewController?

    override var presentedViewController: UIViewController? {
        return self.currentPresentedViewController
    }

}
#endif
