import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
import Nimble
@testable import RevenueCatAdMob
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptTrackingLifecycleTests: AdapterTestCase {

    func testSessionReplacementDoesNotEmitEventsOrChangeVisibleOfferAttribution() async throws {
        let state = PromptLifecycleState()
        let originalSession = RewardedAdPromptSession()
        state.session = originalSession
        state.placement = "original"
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        let replacement = RewardedAdPromptSession()
        state.session = replacement
        state.placement = "replacement"
        state.label = "Updated offer"
        await expect { probe.lastLabel }.toEventually(equal("Updated offer"))
        XCTAssertEqual(probe.shownPlacements, ["original"])
        XCTAssertEqual(probe.preparationCount, 1)
        XCTAssertEqual(probe.appearances, 1)

        try XCTUnwrap(probe.context).accept()

        XCTAssertEqual(probe.acceptedPlacements, ["original"])
        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertTrue(originalSession.consumePromptShown(), "Acceptance resets the shown session")
        XCTAssertTrue(replacement.consumePromptShown(), "The replacement was not consumed by the update")
    }

    func testReplacementSessionTakesEffectOnNextAppearanceWithoutResettingAdState() async throws {
        let state = PromptLifecycleState()
        let originalSession = RewardedAdPromptSession()
        state.session = originalSession
        state.placement = "original"
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        let replacement = RewardedAdPromptSession()
        state.session = replacement
        state.placement = "replacement"
        state.label = "Updated offer"
        await expect { probe.lastLabel }.toEventually(equal("Updated offer"))
        await self.reappear(window, probe: probe)
        try XCTUnwrap(probe.context).accept()

        XCTAssertEqual(probe.shownPlacements, ["original", "replacement"])
        XCTAssertEqual(probe.acceptedPlacements, ["replacement"])
        XCTAssertEqual(probe.preparationCount, 1)
        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertFalse(originalSession.consumePromptShown(), "The previous offer was not accepted")
        XCTAssertTrue(replacement.consumePromptShown(), "Acceptance resets the replacement session")
    }

    func testPlacementChangeAloneKeepsShownAttributionAcrossReappearance() async throws {
        let state = PromptLifecycleState()
        state.session = RewardedAdPromptSession()
        state.placement = "original"
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.placement = "updated"
        state.label = "Updated offer"
        await expect { probe.lastLabel }.toEventually(equal("Updated offer"))
        await self.reappear(window, probe: probe)
        try XCTUnwrap(probe.context).accept()

        XCTAssertEqual(probe.shownPlacements, ["original"])
        XCTAssertEqual(probe.acceptedPlacements, ["original"])
        XCTAssertEqual(probe.preparationCount, 1)
    }

    func testRetainedSessionKeepsShownPlacementAcrossViewRecreation() async throws {
        let state = PromptLifecycleState()
        state.session = RewardedAdPromptSession()
        state.placement = "original"
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.isVisible = false
        await expect { probe.disappearances }.toEventually(equal(1))
        state.placement = "updated"
        state.isVisible = true
        await expect { probe.appearances }.toEventually(equal(2))
        try XCTUnwrap(probe.context).accept()

        XCTAssertEqual(probe.shownPlacements, ["original"])
        XCTAssertEqual(probe.acceptedPlacements, ["original"])
    }

    func testDefaultSessionSurvivesRepeatedAppearancesAndUpdates() async throws {
        let state = PromptLifecycleState()
        state.placement = "original"
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))

        state.placement = "updated"
        state.label = "Updated offer"
        await expect { probe.lastLabel }.toEventually(equal("Updated offer"))
        await self.reappear(window, probe: probe)
        await self.reappear(window, probe: probe)
        try XCTUnwrap(probe.context).accept()

        XCTAssertEqual(probe.shownPlacements, ["original"])
        XCTAssertEqual(probe.acceptedPlacements, ["original"])
        XCTAssertEqual(probe.preparationCount, 1)
    }

    func testReplacingSessionAfterAcceptanceDoesNotRestoreOfferOrCountAnImpression() async throws {
        let state = PromptLifecycleState()
        state.session = RewardedAdPromptSession()
        let probe = PromptLifecycleProbe()
        let window = makePromptLifecycleWindow(state: state, probe: probe)
        defer { window.isHidden = true }
        await expect { probe.appearances }.toEventually(equal(1))
        let context = try XCTUnwrap(probe.context)
        context.accept()
        await expect { probe.disappearances }.toEventually(equal(1))

        let replacement = RewardedAdPromptSession()
        state.session = replacement
        state.resultLabel = "after acceptance"
        await expect { probe.renderedResultLabel }.toEventually(equal("after acceptance"))
        context.accept()

        XCTAssertEqual(probe.appearances, 1)
        XCTAssertEqual(probe.shownCount, 1)
        XCTAssertEqual(probe.acceptedCount, 1)
        XCTAssertEqual(state.rewardedAd.presentationCount, 1)
        XCTAssertTrue(replacement.consumePromptShown())
    }

    private func reappear(_ window: UIWindow, probe: PromptLifecycleProbe) async {
        guard let controller = window.rootViewController else {
            XCTFail("Missing hosting controller")
            return
        }
        let previousAppearances = probe.appearances
        let previousDisappearances = probe.disappearances
        window.rootViewController = UIViewController()
        await expect { probe.disappearances }.toEventually(equal(previousDisappearances + 1))
        window.rootViewController = controller
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        await expect { probe.appearances }.toEventually(equal(previousAppearances + 1))
    }

}
#endif
