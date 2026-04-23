import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class PrecisionMappingTests: AdapterTestCase {

    func testPreciseMapsToExact() {
        XCTAssertEqual(Tracking.Adapter.mapPrecision(.precise).rawValue, "exact")
    }

    func testEstimatedMapsToEstimated() {
        XCTAssertEqual(Tracking.Adapter.mapPrecision(.estimated).rawValue, "estimated")
    }

    func testPublisherProvidedMapsToPublisherDefined() {
        XCTAssertEqual(Tracking.Adapter.mapPrecision(.publisherProvided).rawValue, "publisher_defined")
    }

    func testUnknownMapsToUnknown() {
        XCTAssertEqual(Tracking.Adapter.mapPrecision(.unknown).rawValue, "unknown")
    }

}
#endif
