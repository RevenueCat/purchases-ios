import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@testable import RevenueCatAdMob
import UIKit

@available(iOS 15.0, *)
@MainActor
final class RewardedAdPromptTrackingTests: AdapterTestCase {

    func testAcceptanceResetsSessionSilentlyAndLateAppearanceDoesNotConsumeNextImpression() throws {
        let session = RewardedAdPromptSession()
        var shownCount = 0
        var acceptedCount = 0
        let dependencies = RewardedAdPromptDependencies(
            isPurchasesConfigured: { true },
            loadRewards: { _ in nil },
            trackPromptShown: { _, _ in shownCount += 1 },
            trackPromptAccepted: { _, _ in acceptedCount += 1 }
        )
        let model = self.makeModel(session: session, dependencies: dependencies)
        let window = RewardedAdPromptTestWindow(rootViewController: UIViewController())
        defer { window.isHidden = true }
        model.setPresentationAnchor(try XCTUnwrap(window.rootViewController))
        model.promptDidAppear()
        model.promptDidAppear()
        XCTAssertEqual(shownCount, 1)

        try XCTUnwrap(model.context).accept()
        XCTAssertEqual(acceptedCount, 1)
        XCTAssertEqual(shownCount, 1, "Resetting the session must not emit an impression")
        model.promptDidAppear()
        model.promptDidAppear()
        XCTAssertEqual(shownCount, 1, "Late appearances of the accepted offer must be ignored")

        let nextModel = self.makeModel(session: session, dependencies: dependencies)
        XCTAssertNotNil(nextModel.context)
        XCTAssertEqual(shownCount, 1, "Creating the next offer must not emit an impression")
        nextModel.promptDidAppear()
        nextModel.promptDidAppear()
        XCTAssertEqual(shownCount, 2, "The next offer's appearance must still count exactly once")
        model.promptDidAppear()
        XCTAssertEqual(shownCount, 2)
    }

    private func makeModel(
        session: RewardedAdPromptSession,
        dependencies: RewardedAdPromptDependencies
    ) -> RewardedAdPromptModel {
        return .init(
            session: session,
            ad: MockRewardedAdPromptAd(),
            placement: "placement",
            loadsRewardConfiguration: false,
            callbackDispatcherFactory: { makeUnverifiedPromptCallbacks() },
            dependencies: dependencies
        )
    }

}
#endif
