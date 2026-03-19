import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class RCAdMobPrecisionMappingTests: RCAdMobTestCase {

    func testPreciseMapsToExact() {
        XCTAssertEqual(RCAdMob.mapPrecision(.precise).rawValue, "exact")
    }

    func testEstimatedMapsToEstimated() {
        XCTAssertEqual(RCAdMob.mapPrecision(.estimated).rawValue, "estimated")
    }

    func testPublisherProvidedMapsToPublisherDefined() {
        XCTAssertEqual(RCAdMob.mapPrecision(.publisherProvided).rawValue, "publisher_defined")
    }

    func testUnknownMapsToUnknown() {
        XCTAssertEqual(RCAdMob.mapPrecision(.unknown).rawValue, "unknown")
    }

}
#endif
