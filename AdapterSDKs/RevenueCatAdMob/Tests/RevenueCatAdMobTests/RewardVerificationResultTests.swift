import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RewardVerificationResultTests: AdapterTestCase {

    func testVerifiedProjectionsAndEquality() {
        let result = RewardVerificationResult.verified(.noReward)

        XCTAssertTrue(result.isVerified)
        XCTAssertFalse(result.isFailed)
        XCTAssertEqual(result.verifiedReward, .noReward)
        XCTAssertEqual(result, .verified(.noReward))
    }

    func testFailedProjectionsAndEquality() {
        let result = RewardVerificationResult.failed

        XCTAssertTrue(result.isFailed)
        XCTAssertFalse(result.isVerified)
        XCTAssertNil(result.verifiedReward)
        XCTAssertEqual(result, .failed)
    }

    func testUnsupportedRewardAliasMatchesUnknown() {
        XCTAssertEqual(VerifiedReward.unsupportedReward, .unknown)
    }
}

#endif
