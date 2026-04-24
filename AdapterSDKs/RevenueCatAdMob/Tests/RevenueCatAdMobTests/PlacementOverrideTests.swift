@testable import RevenueCatAdMob
import XCTest

final class PlacementOverrideTests: AdapterTestCase {

    func testKeepLoadTimePlacementPreservesCurrentPlacement() {
        let resolvedPlacement = RewardVerificationPlacementResolver.resolvedPlacement(
            currentPlacement: "load_time_placement",
            override: .keepLoadTimePlacement
        )

        XCTAssertEqual(resolvedPlacement, "load_time_placement")
    }

    func testExplicitNilOverrideClearsCurrentPlacement() {
        let resolvedPlacement = RewardVerificationPlacementResolver.resolvedPlacement(
            currentPlacement: "load_time_placement",
            override: .override(nil)
        )

        XCTAssertNil(resolvedPlacement)
    }
}
