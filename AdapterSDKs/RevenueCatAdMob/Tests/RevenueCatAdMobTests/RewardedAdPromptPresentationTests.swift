import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
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
        let model = self.makeModel(ad: rewardedAd, resultDispatcherFactory: {
            UnverifiedRewardResultDispatcher(onResult: { _ in XCTFail("Presentation should succeed") })
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

    func testMissingAnchorReportsNotPresentedOnceForBothModes() throws {
        for verified in [true, false] {
            try self.assertNotPresented(verified: verified, anchor: nil)
        }
    }

    func testDismissalIsDeliveredThroughSuppliedAdDelegate() throws {
        let rewardedAd = MockRewardedAdPromptAd()
        var results: [RewardedAdPromptUnverifiedResult] = []
        let model = self.makeModel(ad: rewardedAd, resultDispatcherFactory: {
            UnverifiedRewardResultDispatcher(onResult: { results.append($0) })
        })
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        try XCTUnwrap(model.context).accept()

        rewardedAd.delegate?.adDidDismissFullScreenContent?(PresentedAdStub())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.kind, .dismissed)
    }

    func testDetachedAnchorReportsNotPresentedOnceForBothModes() throws {
        for verified in [true, false] {
            try self.assertNotPresented(verified: verified, anchor: UIViewController())
        }
    }

    func testAnchorDetachedAfterResolutionReportsNotPresentedForBothModes() throws {
        for verified in [true, false] {
            let anchor = UIViewController()
            let window = RewardedAdPromptTestWindow(rootViewController: anchor)
            defer { window.isHidden = true }
            XCTAssertNotNil(anchor.rewardedAdPromptPresentationViewController)

            try self.assertNotPresented(verified: verified, anchor: anchor) {
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
    ) throws {
        let rewardedAd = MockRewardedAdPromptAd()
        var errors: [RewardedAdPromptError] = []
        var acceptanceCount = 0
        let model = self.makeModel(ad: rewardedAd, resultDispatcherFactory: {
            if verified {
                return VerifiedRewardResultDispatcher(onResult: { result in
                    XCTAssertEqual(result.kind, .notPresented)
                    XCTAssertNil(result.rewardVerificationResult)
                    if let error = result.presentationError { errors.append(error) }
                })
            } else {
                return UnverifiedRewardResultDispatcher(onResult: { result in
                    XCTAssertEqual(result.kind, .notPresented)
                    if let error = result.presentationError { errors.append(error) }
                })
            }
        }, trackAccepted: { acceptanceCount += 1 })
        if let anchor { model.setPresentationAnchor(anchor) }
        let context = try XCTUnwrap(model.context)
        beforeAcceptance()

        context.accept()
        context.accept()

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
        resultDispatcherFactory: @escaping @MainActor () -> any RewardedAdPromptResultDispatching,
        trackAccepted: @escaping () -> Void = {}
    ) -> RewardedAdPromptModel {
        return .init(
            session: RewardedAdPromptSession(),
            ad: rewardedAd,
            placement: nil,
            resultDispatcherFactory: resultDispatcherFactory,
            dependencies: .init(
                isPurchasesConfigured: { true },
                loadConfiguredRewards: { _ in
                    XCTFail("Presentation must not fetch metadata")
                    return nil
                },
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
