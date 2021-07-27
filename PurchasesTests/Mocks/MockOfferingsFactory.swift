//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
@testable import RevenueCat
import StoreKit

class MockOfferingsFactory: OfferingsFactory {

    var emptyOfferings = false
    var badOfferings = false
    
    override func createOfferings(withProductWrappers products: [String: ProductWrapper],
                                  data: [String: Any]) -> Offerings? {
        if (emptyOfferings) {
            return Offerings(offerings: [:], currentOfferingID: "base")
        }
        if (badOfferings) {
            return nil
        }

        let product = MockSKProduct(mockProductIdentifier: "monthly_freetrial")
        let productWrapper = SK1ProductWrapper(sk1Product: product)
        return Offerings(
            offerings: [
                "base": Offering(
                    identifier: "base",
                    serverDescription: "This is the base offering",
                    availablePackages: [
                        Package(identifier: "$rc_monthly",
                                packageType: PackageType.monthly,
                                productWrapper: productWrapper,
                                offeringIdentifier: "base")
                    ]
                )],
            currentOfferingID: "base")
    }
}
