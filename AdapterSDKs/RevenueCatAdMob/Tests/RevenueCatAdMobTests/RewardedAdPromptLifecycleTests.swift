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
final class RewardedAdPromptLifecycleTests: AdapterTestCase {

    func testFirstContentBuildReceivesCachedRewardsForBothPromptTypesAndAdFormats() async throws {
        let rewards = ConfiguredAdRewards(reward: .unsupportedReward)
        for usesVerification in [false, true] {
            for usesInterstitial in [false, true] {
                let state = PromptLifecycleState()
                state.usesVerification = usesVerification
                state.usesInterstitial = usesInterstitial
                let probe = PromptLifecycleProbe()
                probe.cachedRewards = { rewards }
                let window = makePromptLifecycleWindow(state: state, probe: probe)
                defer { window.isHidden = true }
                await expect { probe.appearances }.toEventually(equal(1))

                XCTAssertEqual(try XCTUnwrap(probe.renderedConfigurations.first), rewards)
                XCTAssertTrue(probe.renderedConfigurations.allSatisfy { $0 == rewards })
                XCTAssertEqual(probe.cachedRewardsReadCount, 1)
                XCTAssertEqual(probe.shownCount, 1)
            }
        }
    }

    func testReplacingAdReadsNewCachedSnapshotWithoutAnIntermediateNilConfiguration() async throws {
        let state = PromptLifecycleState()
        let probe = PromptLifecycleProbe()
        let firstRewards = ConfiguredAdRewards(reward: .unsupportedReward)
        probe.cachedRewards = { firstRewards }
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))
        XCTAssertEqual(try XCTUnwrap(probe.renderedConfigurations.first), firstRewards)

        let replacementRewards = ConfiguredAdRewards(reward: nil, moreRewards: [])
        probe.cachedRewards = { replacementRewards }
        state.rewardedAd = LifecycleRewardedAd()
        await expect { probe.appearances }.toEventually(equal(2))

        XCTAssertEqual(probe.context?.rewardConfiguration, replacementRewards)
        XCTAssertTrue(probe.renderedConfigurations.allSatisfy { $0 != nil })
        XCTAssertEqual(probe.cachedRewardsReadCount, 2)
    }

    func testParentUpdatesPreserveDefaultSessionAndPresentationState() async throws {
        let state = PromptLifecycleState()
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.label = "Updated offer"
        await expect { probe.lastLabel }.toEventually(equal("Updated offer"))
        XCTAssertEqual(probe.shownCount, 1)
        XCTAssertEqual(probe.cachedRewardsReadCount, 1)

        try XCTUnwrap(probe.context).accept()
        await expect { probe.disappearances }.toEventually(equal(1))
        state.label = "Another update"
        await self.flushUpdates(window)

        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertEqual(probe.acceptedCount, 1)
        XCTAssertEqual(probe.appearances, 1)
        XCTAssertEqual(probe.shownCount, 1)
    }

    func testReplacingAdFromSameUnitPresentsNewInstanceWithoutCallerIdentity() async throws {
        let state = PromptLifecycleState()
        let originalAd = state.rewardedAd
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.rewardedAd = LifecycleRewardedAd()
        await expect { probe.appearances }.toEventually(equal(2))
        await expect { probe.cachedRewardsReadCount }.toEventually(equal(2))
        try XCTUnwrap(probe.context).accept()

        XCTAssertEqual(originalAd.adUnitID, state.rewardedAd.adUnitID)
        XCTAssertEqual(originalAd.presentationCount, 0)
        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertEqual(probe.shownCount, 2)
    }

    func testReplacingAcceptedAdRestoresOfferAndUsesNewResultHandler() async throws {
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

        XCTAssertTrue(probe.resultLabels.isEmpty)
        state.rewardedAd.fullScreenContentDelegate?.adDidDismissFullScreenContent?(state.rewardedAd)

        XCTAssertEqual(originalAd.presentationCount, 1)
        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertEqual(probe.acceptedCount, 2)
        XCTAssertEqual(probe.resultLabels, ["replacement"])
    }

    func testAcceptedRewardWaitsForDismissalAfterPromptRemovalOrReplacement() async throws {
        for replacesAd in [false, true] {
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
                await self.flushUpdates(window)
            }

            originalAd.rewardEarned?()
            XCTAssertTrue(probe.resultLabels.isEmpty)

            let delegate = try XCTUnwrap(originalAd.fullScreenContentDelegate)
            delegate.adDidDismissFullScreenContent?(originalAd)
            delegate.adDidDismissFullScreenContent?(originalAd)

            XCTAssertEqual(probe.resultLabels, ["original"])
        }
    }

    func testReplacingAdPreservesCallerSessionUntilAcceptance() async throws {
        let state = PromptLifecycleState()
        state.session = RewardedAdPromptSession()
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.rewardedAd = LifecycleRewardedAd()
        await expect { probe.appearances }.toEventually(equal(2))
        XCTAssertEqual(probe.shownCount, 1)

        try XCTUnwrap(probe.context).accept()
        await expect { probe.disappearances }.toEventually(equal(2))
        state.rewardedAd = LifecycleRewardedAd()
        await expect { probe.appearances }.toEventually(equal(3))
        XCTAssertEqual(probe.shownCount, 2, "Acceptance still resets the caller's tracking session")
    }

    func testRemovalAndReinsertionWithDefaultSessionCountsNewAppearance() async {
        await self.checkRemovalAndReinsertion(session: nil, expectedShownCount: 2)
    }

    func testRemovalAndReinsertionWithRetainedSessionDeduplicatesAppearance() async {
        await self.checkRemovalAndReinsertion(session: RewardedAdPromptSession(), expectedShownCount: 1)
    }

    func testSameAdUsesUpdatedResultHandlerWhenAccepted() async throws {
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

            XCTAssertEqual(probe.resultLabels, ["updated"])
            XCTAssertEqual(state.rewardedAd.presentationCount, 1)
            XCTAssertEqual(probe.shownCount, 1)
            XCTAssertEqual(probe.acceptedCount, 1)
            XCTAssertEqual(probe.cachedRewardsReadCount, 1)
        }
    }

    func testSameAdKeepsAcceptedResultHandlerAfterFurtherViewUpdates() async throws {
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

            XCTAssertEqual(probe.resultLabels, ["original"])
            XCTAssertEqual(state.rewardedAd.presentationCount, 1)
            XCTAssertEqual(probe.shownCount, 1)
            XCTAssertEqual(probe.acceptedCount, 1)
            XCTAssertEqual(probe.cachedRewardsReadCount, 1)
        }
    }

    func testBothPromptTypesAndNativeAdFormatsRefreshOnReplacement() async {
        for usesVerification in [false, true] {
            for usesInterstitial in [false, true] {
                let state = PromptLifecycleState()
                state.usesVerification = usesVerification
                state.usesInterstitial = usesInterstitial
                let probe = PromptLifecycleProbe()
                let window = makePromptLifecycleWindow(state: state, probe: probe)
                await expect { probe.appearances }.toEventually(equal(1))

                state.rewardedAd = LifecycleRewardedAd()
                state.interstitialAd = LifecycleRewardedInterstitialAd()
                await expect { probe.appearances }.toEventually(equal(2))
                await expect { probe.cachedRewardsReadCount }.toEventually(equal(2))

                XCTAssertEqual(probe.shownCount, 2)
                window.isHidden = true
            }
        }
    }

    private func checkRemovalAndReinsertion(session: RewardedAdPromptSession?, expectedShownCount: Int) async {
        let state = PromptLifecycleState()
        state.session = session
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.isVisible = false
        await expect { probe.disappearances }.toEventually(equal(1))
        state.isVisible = true
        await expect { probe.appearances }.toEventually(equal(2))

        XCTAssertEqual(probe.shownCount, expectedShownCount)
        XCTAssertEqual(probe.cachedRewardsReadCount, 2)
    }

    private func flushUpdates(_ window: UIWindow) async {
        let updated = expectation(description: "SwiftUI update processed")
        DispatchQueue.main.async {
            window.layoutIfNeeded()
            updated.fulfill()
        }
        await self.fulfillment(of: [updated], timeout: 1)
    }

}
#endif
