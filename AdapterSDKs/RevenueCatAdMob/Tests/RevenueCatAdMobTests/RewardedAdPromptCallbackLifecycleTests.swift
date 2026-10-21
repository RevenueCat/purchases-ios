import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import GoogleMobileAds
import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatAdMob
import SwiftUI
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptCallbackLifecycleTests: AdapterTestCase {

    func testReplacingAcceptedAdRestoresOfferAndUsesNewCallbacks() async throws {
        let state = PromptLifecycleState()
        let originalAd = state.rewardedAd
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))
        try XCTUnwrap(probe.context).accept()
        await expect { probe.disappearances }.toEventually(equal(1))

        state.resultLabel = "replacement"
        state.rewardedAd = LifecycleRewardedAd()
        await expect { probe.appearances }.toEventually(equal(2))
        try XCTUnwrap(probe.context).accept()
        state.rewardedAd.rewardEarned?()

        XCTAssertEqual(probe.rewardLabels, ["replacement"])
        state.rewardedAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(state.rewardedAd)

        XCTAssertEqual(originalAd.presentationCount, 1)
        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertEqual(probe.acceptedCount, 2)
        XCTAssertEqual(probe.rewardLabels, ["replacement"])
    }

    func testAcceptedRewardAndDismissalSurvivePromptRemovalOrReplacementInEitherOrder() async throws {
        for replacesAd in [false, true] {
            for dismissesFirst in [false, true] {
                let state = PromptLifecycleState()
                let originalAd = state.rewardedAd
                let probe = PromptLifecycleProbe()
                let window = makePromptLifecycleWindow(state: state, probe: probe)
                defer { window.isHidden = true }
                await expect { probe.appearances }.toEventually(equal(1))
                try XCTUnwrap(probe.context).accept()
                await expect { probe.disappearances }.toEventually(equal(1))

                state.resultLabel = "replacement"
                if replacesAd {
                    state.rewardedAd = LifecycleRewardedAd()
                    await expect { probe.appearances }.toEventually(equal(2))
                } else {
                    state.isVisible = false
                    await expect { probe.renderedResultLabel }.toEventually(equal("replacement"))
                }

                let delegate = try XCTUnwrap(originalAd.fullScreenContentDelegate)
                if dismissesFirst {
                    delegate.adDidDismissFullScreenContent?(originalAd)
                    XCTAssertEqual(probe.dismissalLabels, ["original"])
                    XCTAssertTrue(probe.rewardLabels.isEmpty)
                }
                originalAd.rewardEarned?()
                XCTAssertEqual(probe.rewardLabels, ["original"])
                if !dismissesFirst {
                    XCTAssertTrue(probe.dismissalLabels.isEmpty)
                }
                delegate.adDidDismissFullScreenContent?(originalAd)
                originalAd.rewardEarned?()

                XCTAssertEqual(probe.rewardLabels, ["original"])
                XCTAssertEqual(probe.dismissalLabels, ["original"])
            }
        }
    }

    func testAcceptedPresentationFailureKeepsOriginalHandlerAfterViewUpdates() async throws {
        for usesVerification in [false, true] {
            let state = PromptLifecycleState(usesVerification: usesVerification)
            let originalAd = state.rewardedAd
            let probe = PromptLifecycleProbe()
            let window = makePromptLifecycleWindow(state: state, probe: probe)
            defer { window.isHidden = true }
            await expect { probe.appearances }.toEventually(equal(1))
            try XCTUnwrap(probe.context).accept()
            await expect { probe.disappearances }.toEventually(equal(1))

            state.resultLabel = "replacement"
            state.rewardedAd = LifecycleRewardedAd()
            await expect { probe.appearances }.toEventually(equal(2))
            let delegate = try XCTUnwrap(originalAd.fullScreenContentDelegate)
            let error = NSError(domain: "test.presentation", code: 1)
            delegate.ad?(originalAd, didFailToPresentFullScreenContentWithError: error)
            delegate.ad?(originalAd, didFailToPresentFullScreenContentWithError: error)
            XCTAssertTrue(probe.failureLabels.isEmpty)

            await expect { probe.failureLabels }.toEventually(equal(["original"]))
            XCTAssertTrue(probe.rewardLabels.isEmpty)
            XCTAssertTrue(probe.dismissalLabels.isEmpty)
        }
    }

    func testSameAdUsesUpdatedCallbacksWhenAccepted() async throws {
        for usesVerification in [false, true] {
            let state = PromptLifecycleState(usesVerification: usesVerification)
            let probe = PromptLifecycleProbe()
            let window = makePromptLifecycleWindow(state: state, probe: probe)
            defer { window.isHidden = true }
            await expect { probe.appearances }.toEventually(equal(1))

            state.resultLabel = "updated"
            await expect { probe.renderedResultLabel }.toEventually(equal("updated"))
            try XCTUnwrap(probe.context).accept()
            state.rewardedAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(state.rewardedAd)

            XCTAssertEqual(probe.dismissalLabels, ["updated"])
            XCTAssertEqual(state.rewardedAd.presentationCount, 1)
            XCTAssertEqual(probe.shownCount, 1)
            XCTAssertEqual(probe.acceptedCount, 1)
            XCTAssertEqual(probe.rewardsLoadCount, usesVerification ? 1 : 0)
        }
    }

    func testSameAdKeepsAcceptedCallbacksAfterFurtherViewUpdates() async throws {
        for usesVerification in [false, true] {
            let state = PromptLifecycleState(usesVerification: usesVerification)
            let probe = PromptLifecycleProbe()
            let window = makePromptLifecycleWindow(state: state, probe: probe)
            defer { window.isHidden = true }
            await expect { probe.appearances }.toEventually(equal(1))
            try XCTUnwrap(probe.context).accept()
            await expect { probe.disappearances }.toEventually(equal(1))

            state.resultLabel = "after acceptance"
            await expect { probe.renderedResultLabel }.toEventually(equal("after acceptance"))
            state.rewardedAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(state.rewardedAd)
            state.rewardedAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(state.rewardedAd)

            XCTAssertEqual(probe.dismissalLabels, ["original"])
            XCTAssertEqual(state.rewardedAd.presentationCount, 1)
            XCTAssertEqual(probe.shownCount, 1)
            XCTAssertEqual(probe.acceptedCount, 1)
            XCTAssertEqual(probe.rewardsLoadCount, usesVerification ? 1 : 0)
        }
    }

}
#endif
