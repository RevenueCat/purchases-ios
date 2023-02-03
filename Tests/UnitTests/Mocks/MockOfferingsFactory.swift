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
            return Offerings(offerings: [:], currentOfferingID: "base")
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
                    availablePackages: [
                        Package(identifier: "$rc_monthly",
                                packageType: PackageType.monthly,
                                storeProduct: storeProduct,
                                offeringIdentifier: "base")
                    ]
                )],
            currentOfferingID: "base")
    }
}
