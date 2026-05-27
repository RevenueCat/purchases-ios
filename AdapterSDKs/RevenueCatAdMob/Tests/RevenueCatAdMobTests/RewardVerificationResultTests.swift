import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RewardVerificationResultTests: AdapterTestCase {

    func testVerifiedProjectionsAndEquality() {
        let result = RewardVerificationResult.verified(.noReward)

        XCTAssertFalse(result.isFailed)
        XCTAssertEqual(result.reward, .noReward)
        XCTAssertEqual(result, .verified(.noReward))
    }

    func testFailedProjectionsAndEquality() {
        let result = RewardVerificationResult.failed

        XCTAssertTrue(result.isFailed)
        XCTAssertNil(result.reward)
        XCTAssertEqual(result, .failed)
    }

    func testUnsupportedRewardResult() {
        let result = RewardVerificationResult.verified(.unsupportedReward)
        XCTAssertEqual(result.reward, .unsupportedReward)
    }
}

#endif
