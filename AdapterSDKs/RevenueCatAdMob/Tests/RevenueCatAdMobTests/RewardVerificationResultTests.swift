import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RewardVerificationResultTests: AdapterTestCase {

    func testVerifiedProjectionsAndEquality() {
        let result = RewardVerificationResult.verified(.noReward)

        XCTAssertFalse(result.isFailed)
        XCTAssertEqual(result.verifiedReward, .noReward)
        XCTAssertEqual(result, .verified(.noReward))
    }

    func testFailedProjectionsAndEquality() {
        let result = RewardVerificationResult.failed

        XCTAssertTrue(result.isFailed)
        XCTAssertNil(result.verifiedReward)
        XCTAssertEqual(result, .failed)
    }

    func testUnsupportedRewardResult() {
        let result = RewardVerificationResult.verified(.unsupportedReward)
        XCTAssertEqual(result.verifiedReward, .unsupportedReward)
    }
}

#endif
