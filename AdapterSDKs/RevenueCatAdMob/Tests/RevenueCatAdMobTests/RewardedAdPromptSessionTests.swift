import XCTest

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RewardedAdPromptSessionTests: AdapterTestCase {

    @MainActor
    func testConsumesPromptShownOnlyOnceUntilAcceptance() {
        let session = RewardedAdPromptSession()

        XCTAssertTrue(session.consumePromptShown())
        XCTAssertFalse(session.consumePromptShown())

        session.resetAfterAcceptance()

        XCTAssertTrue(session.consumePromptShown())
        XCTAssertFalse(session.consumePromptShown())
    }

    @MainActor
    func testNilShownPlacementIsPreservedUntilAcceptanceResetsSession() {
        let session = RewardedAdPromptSession()

        XCTAssertTrue(session.consumePromptShown(placement: nil))
        XCTAssertNil(session.placementForAcceptance(fallback: "updated"))
        XCTAssertFalse(session.consumePromptShown(placement: "updated"))
        XCTAssertNil(session.placementForAcceptance(fallback: "updated"))

        session.resetAfterAcceptance()

        XCTAssertEqual(session.placementForAcceptance(fallback: "updated"), "updated")
        XCTAssertTrue(session.consumePromptShown(placement: "next"))
        XCTAssertEqual(session.placementForAcceptance(fallback: "updated"), "next")
    }

}
#endif
