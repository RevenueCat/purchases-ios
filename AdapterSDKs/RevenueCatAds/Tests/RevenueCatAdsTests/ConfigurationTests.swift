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

@MainActor
final class AdsConfigureTests: TestCase {

    private var module: FakeAdModule!

    override func setUp() async throws {
        try await super.setUp()
        let module = FakeAdModule()
        self.module = module
        RCAds.makeModule = { module }
        RCAds.reset()
    }

    override func tearDown() async throws {
        RCAds.makeModule = { PrebidAdModule() }
        RCAds.reset()
        try await super.tearDown()
    }

    func testConfigureInitializesModule() throws {
        try RCAds.configure(with: AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("http://localhost:8080")))

        XCTAssertTrue(RCAds.module === self.module)
        XCTAssertEqual(self.module.initializedConfigurations, [
            ResolvedAdsConfiguration(
                apiKey: "appl_key",
                auctionURL: makeURL("http://localhost:8080/v1/ads/openrtb2/auction")
            )
        ])
    }

    func testConfigureFailureLeavesAdsUnconfigured() {
        self.module.initializeError = AdsError(code: .invalidConfiguration, message: "rejected")

        XCTAssertThrowsError(try RCAds.configure(with: AdsConfiguration(apiKey: "appl_key"))) {
            XCTAssertEqual(($0 as? AdsError)?.code, .invalidConfiguration)
        }
        XCTAssertNil(RCAds.module)
    }

    func testInterstitialUsesConfiguredModule() async throws {
        try RCAds.configure(with: AdsConfiguration(apiKey: "appl_key"))
        self.module.interstitialEvent = .loaded

        let interstitial = AdsInterstitial(placementID: "placement")
        try await interstitial.load()

        XCTAssertEqual(self.module.lastInterstitial?.placementID, "placement")
    }

}

final class PrebidErrorMappingTests: TestCase {

    func testNoBidsMapsToNoFill() {
        let prebidError = NSError(domain: "org.prebid.mobile", code: 1, userInfo: [
            "PrebidResultCodeKey": 7
        ])

        let error = PrebidInterstitial.adsError(from: prebidError)

        XCTAssertEqual(error.code, .noFill)
        XCTAssertEqual(error.underlyingError as NSError?, prebidError)
    }

    func testOtherErrorsMapToLoadFailed() {
        let prebidError = NSError(domain: "org.prebid.mobile", code: 2, userInfo: [
            "PrebidResultCodeKey": 5
        ])

        let error = PrebidInterstitial.adsError(from: prebidError)

        XCTAssertEqual(error.code, .loadFailed)
        XCTAssertEqual(error.underlyingError as NSError?, prebidError)
    }

    func testMissingErrorMapsToLoadFailed() {
        let error = PrebidInterstitial.adsError(from: nil)

        XCTAssertEqual(error.code, .loadFailed)
        XCTAssertNil(error.underlyingError)
    }

}

#endif
