//
//  ConfigurationTests.swift
//
//  Created by RevenueCat.
//

import XCTest

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

    func testFallsBackToPurchasesValuesAndDropsProxyPathLikeCore() throws {
        let resolved = try AdsConfiguration().resolve(
            purchasesAPIKey: "appl_purchases",
            purchasesProxyURL: makeURL("https://proxy.example.com/base")
        )

        XCTAssertEqual(resolved.apiKey, "appl_purchases")
        XCTAssertEqual(resolved.auctionURL.absoluteString, "https://proxy.example.com/v1/ads/openrtb2/auction")
    }

    func testExplicitServerURLWithPurchasesAPIKey() throws {
        let configuration = AdsConfiguration(serverURL: makeURL("http://localhost:8080"))

        let resolved = try configuration.resolve(
            purchasesAPIKey: "appl_purchases",
            purchasesProxyURL: makeURL("https://proxy.example.com")
        )

        XCTAssertEqual(resolved.apiKey, "appl_purchases")
        XCTAssertEqual(resolved.auctionURL.absoluteString, "http://localhost:8080/v1/ads/openrtb2/auction")
    }

    func testExplicitAPIKeyWithPurchasesProxyURL() throws {
        let configuration = AdsConfiguration(apiKey: "appl_explicit")

        let resolved = try configuration.resolve(
            purchasesAPIKey: "appl_purchases",
            purchasesProxyURL: makeURL("https://proxy.example.com")
        )

        XCTAssertEqual(resolved.apiKey, "appl_explicit")
        XCTAssertEqual(resolved.auctionURL.absoluteString, "https://proxy.example.com/v1/ads/openrtb2/auction")
    }

    func testUppercaseSchemeIsAccepted() throws {
        let configuration = AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("HTTPS://proxy.example.com"))

        let resolved = try configuration.resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)

        XCTAssertEqual(resolved.auctionURL.scheme?.lowercased(), "https")
        XCTAssertEqual(resolved.auctionURL.host, "proxy.example.com")
        XCTAssertEqual(resolved.auctionURL.path, "/v1/ads/openrtb2/auction")
    }

    func testTrailingSlashServerURLDoesNotDoubleTheSlash() throws {
        let configuration = AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("https://proxy.example.com/"))

        let resolved = try configuration.resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)

        XCTAssertEqual(resolved.auctionURL.absoluteString, "https://proxy.example.com/v1/ads/openrtb2/auction")
    }

    func testFallsBackToDefaultHost() throws {
        let resolved = try AdsConfiguration().resolve(purchasesAPIKey: "appl_purchases", purchasesProxyURL: nil)

        XCTAssertEqual(resolved.auctionURL.absoluteString, "https://api.revenuecat.com/v1/ads/openrtb2/auction")
    }

    func testMissingAPIKeyThrowsNotConfigured() {
        XCTAssertThrowsError(try AdsConfiguration().resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .notConfigured)
        }
        XCTAssertThrowsError(try AdsConfiguration().resolve(purchasesAPIKey: "", purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .notConfigured)
        }
    }

    func testExplicitlyEmptyAPIKeyThrowsInvalidConfiguration() {
        let configuration = AdsConfiguration(apiKey: "")

        XCTAssertThrowsError(try configuration.resolve(purchasesAPIKey: "appl_purchases", purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .invalidConfiguration)
        }
        XCTAssertThrowsError(try configuration.resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .invalidConfiguration)
        }
    }

    func testHostlessServerURLThrowsInvalidConfiguration() {
        let configuration = AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("https://"))

        XCTAssertThrowsError(try configuration.resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .invalidConfiguration)
        }
    }

    func testNonHTTPServerURLThrowsInvalidConfiguration() {
        let configuration = AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("ftp://example.com"))

        XCTAssertThrowsError(try configuration.resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)) {
            XCTAssertEqual(($0 as? AdsError)?.code, .invalidConfiguration)
        }
    }

}
