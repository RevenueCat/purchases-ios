import XCTest

#if (os(iOS) || targetEnvironment(macCatalyst)) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCat_AdMob

@available(iOS 15.0, *)
final class RCAdMobRevenueConversionTests: RCAdMobTestCase {

    func testRevenueMicrosConvertsFractionalUnitsToMicros() {
        XCTAssertEqual(
            RCAdMob.revenueMicros(from: NSDecimalNumber(string: "0.005")),
            5000
        )
    }

    func testRevenueMicrosConvertsWholeAndFractionalUnitsToMicros() {
        XCTAssertEqual(
            RCAdMob.revenueMicros(from: NSDecimalNumber(string: "1.5")),
            1_500_000
        )
    }

}
#endif
