//
//  PrebidAdModuleTests.swift
//
//  Created by RevenueCat.
//

import XCTest

#if os(iOS) && canImport(PrebidMobile)
@_spi(PBMInternal) import PrebidMobile
@_spi(Experimental) @testable import RevenueCatAds

@MainActor
final class PrebidAdModuleTests: TestCase {

    override func tearDown() async throws {
        Prebid.shared.clearCustomHeaders()
        Prebid.shared.prebidServerAccountId = ""
        try await super.tearDown()
    }

    func testInitializeConfiguresPrebidForTheAuctionEndpoint() throws {
        let configuration = try AdsConfiguration(apiKey: "appl_key", serverURL: makeURL("http://localhost:8080"))
            .resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)

        try PrebidAdModule().initialize(with: configuration)

        XCTAssertEqual(try Host.shared.getHostURL(), "http://localhost:8080/v1/ads/openrtb2/auction")
        XCTAssertEqual(Prebid.shared.customHeaders["Authorization"], "Bearer appl_key")
        XCTAssertEqual(Prebid.shared.prebidServerAccountId, "revenuecat")
        XCTAssertTrue(Prebid.shared.shouldDisableStatusCheck)
    }

    func testReconfiguringReplacesTheAuthorizationHeader() throws {
        let module = PrebidAdModule()

        let first = try AdsConfiguration(apiKey: "appl_one").resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)
        let second = try AdsConfiguration(apiKey: "appl_two").resolve(purchasesAPIKey: nil, purchasesProxyURL: nil)

        try module.initialize(with: first)
        try module.initialize(with: second)

        XCTAssertEqual(Prebid.shared.customHeaders["Authorization"], "Bearer appl_two")
    }

    func testNetworkNameIsTheWinningBidder() {
        let response = BidResponse(jsonDictionary: [
            "id": "response",
            "seatbid": [[
                "seat": "smartadserver",
                "bid": [[
                    "id": "1", "impid": "1", "price": 1.5,
                    "ext": ["prebid": ["targeting": [
                        "hb_pb": "1.50", "hb_bidder": "smartadserver", "hb_cache_id": "cache"
                    ]]]
                ]]
            ]]
        ])

        XCTAssertEqual(response.winningBid?.price, 1.5)
        XCTAssertEqual(PrebidInterstitial.networkName(from: response), "smartadserver")
    }

    func testNetworkNameFallsBackWhenThereIsNoWinningBid() {
        XCTAssertEqual(PrebidInterstitial.networkName(from: nil), "")
        XCTAssertEqual(PrebidInterstitial.networkName(from: BidResponse(jsonDictionary: [:])), "")
    }

    func testNoContentResponseMapsToNoFill() {
        let error = PrebidInterstitial.adsError(from: PBMError.blankResponse())

        XCTAssertEqual(error.code, .noFill)
    }

    func testNoWinningBidMapsToNoFill() {
        let error = PrebidInterstitial.adsError(from: PBMError.noWinningBid())

        XCTAssertEqual(error.code, .noFill)
    }

}

#endif
