//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
@testable import RevenueCat
import StoreKit

class MockOfferingsFactory: OfferingsFactory {

    var emptyOfferings = false
    var nilOfferings = false

    override func createOfferings(
        from storeProductsByID: [String: StoreProduct],
        contents: Offerings.Contents
    ) -> Offerings? {
        if emptyOfferings {
            let response = OfferingsResponse(currentOfferingId: "base",
                                             offerings: [],
                                             placements: nil,
                                             targeting: nil,
                                             uiConfig: nil)
            return Offerings(offerings: [:],
                             currentOfferingID: "base",
                             placements: nil,
                             targeting: nil,
                             contents: Offerings.Contents(response: response,
                                                          fromFallbackUrl: false,
                                                          fromLoadShedder: false))
        }
        if nilOfferings {
            return nil
        }

        let product = MockSK1Product(mockProductIdentifier: "monthly_freetrial")
        let storeProduct = SK1StoreProduct(sk1Product: product)

        return Offerings(
            offerings: [
                "base": Offering( // Corresponds to the OfferingsManagerTests.anyBackendOfferingsContents
                    identifier: "base",
                    serverDescription: "This is the base offering",
                    metadata: [:],
                    availablePackages: [
                        Package(identifier: "$rc_monthly",
                                packageType: .monthly,
                                storeProduct: .from(product: storeProduct),
                                offeringIdentifier: "base",
                                webCheckoutUrl: nil)
                    ],
                    webCheckoutUrl: nil
                )],
            currentOfferingID: "base",
            placements: nil,
            targeting: nil,
            contents: contents)
    }
}

extension MockOfferingsFactory: @unchecked Sendable { }

extension OfferingsResponse {

    static let mockResponse: Self = .init(
        currentOfferingId: "base",
        offerings: [
            .init(identifier: "base",
                  description: "This is the base offering",
                  packages: [
                    .init(identifier: "$rc_monthly",
                          platformProductIdentifier: "monthly_freetrial",
                          webCheckoutUrl: nil)
                  ], webCheckoutUrl: nil)
        ],
        placements: nil,
        targeting: nil,
        uiConfig: nil
    )

}

extension Offerings.Contents {

    static let mockContents: Self = .init(response: .mockResponse, fromFallbackUrl: false, fromLoadShedder: false)

}
