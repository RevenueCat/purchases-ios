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
        data: OfferingsResponse
    ) -> Offerings? {
        if emptyOfferings {
            return Offerings(offerings: [:],
                             currentOfferingID: "base",
                             response: .init(currentOfferingId: "base", offerings: []))
        }
        if nilOfferings {
            return nil
        }

        let product = MockSK1Product(mockProductIdentifier: "monthly_freetrial")
        let storeProduct = SK1StoreProduct(sk1Product: product)

        return Offerings(
            offerings: [
                "base": Offering(
                    identifier: "base",
                    serverDescription: "This is the base offering",
                    metadata: [:],
                    availablePackages: [
                        Package(identifier: "$rc_monthly",
                                packageType: .monthly,
                                storeProduct: .from(product: storeProduct),
                                offeringIdentifier: "base")
                    ]
                )],
            currentOfferingID: "base",
            response: .init(currentOfferingId: "base", offerings: [
                .init(identifier: "base", description: "This is the base offering",
                      packages: [
                        .init(identifier: "", platformProductIdentifier: "$rc_monthly")
                      ])
            ])
        )
    }
}

extension OfferingsResponse {

    static let mockResponse: Self = .init(
        currentOfferingId: "base",
        offerings: [
            .init(identifier: "base",
                  description: "This is the base offering",
                  packages: [
                    .init(identifier: "$rc_monthly", platformProductIdentifier: "monthly_freetrial")
                  ])
        ]
    )

}
