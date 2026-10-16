//
//  ConfigurationTests.swift
//
//  Created by RevenueCat.
//

import XCTest

#if os(iOS) && canImport(PrebidMobile)
@_spi(Experimental) @testable import RevenueCatAds

final class AdsConfigurationResolutionTests: TestCase {

    func testExplicitValuesWin() throws {
        let configuration = AdsConfiguration(apiKey: "appl_explicit", serverURL: makeURL("http://localhost:8080"))

        let resolved = try configuration.resolve(
            purchasesAPIKey: "appl_purchases",
            purchasesProxyURL: makeURL("https://proxy.example.com")
        )

        XCTAssertEqual(resolved.apiKey, "appl_explicit")
        XCTAssertEqual(resolved.auctionURL.absoluteString, "http://localhost:8080/v1/ads/openrtb2/auction")
    }

    func testFallsBackToPurchasesValues() throws {
        let resolved = try AdsConfiguration().resolve(
            purchasesAPIKey: "appl_purchases",
            purchasesProxyURL: makeURL("https://proxy.example.com/base")
        )

        XCTAssertEqual(resolved.apiKey, "appl_purchases")
        XCTAssertEqual(resolved.auctionURL.absoluteString, "https://proxy.example.com/base/v1/ads/openrtb2/auction")
    }

    func testFallsBackToDefaultHost() throws {
        let resolved = try AdsConfiguration().resolve(purchasesAPIKey: "appl_purchases", purchasesProxyURL: nil)

        XCTAssertEqual(resolved.auctionURL.absoluteString, "https://api.revenuecat.com/v1/ads/openrtb2/auction")
    }

    func testMissingAPIKeyThrowsNotConfigured() {
        XCTAssertThrowsError(try AdsConfiguration().resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .notConfigured)
        }
        XCTAssertThrowsError(try AdsConfiguration(apiKey: "").resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .notConfigured)
        }
    }

    func testNonHTTPServerURLThrowsInvalidConfiguration() {
        let configuration = AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("ftp://example.com"))

        XCTAssertThrowsError(try configuration.resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .invalidConfiguration)
        }
    }

}

#endif
