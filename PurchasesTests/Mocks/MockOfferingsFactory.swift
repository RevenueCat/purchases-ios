//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//
@testable import RevenueCat
import StoreKit

class MockOfferingsFactory: OfferingsFactory {

    var emptyOfferings = false
    var nilOfferings = false

    override func createOfferings(withProducts products: [String: SKProduct],
                                  data: [String: Any]) -> Offerings? {
        if (emptyOfferings) {
            return Offerings(offerings: [:], currentOfferingID: "base")
        }
        if (nilOfferings) {
            return nil
        }
        return Offerings(
            offerings: [
                "base": Offering(
                    identifier: "base",
                    serverDescription: "This is the base offering",
                    availablePackages: [
                        Package(identifier: "$rc_monthly",
                                packageType: PackageType.monthly,
                                product: MockSKProduct(mockProductIdentifier: "monthly_freetrial"),
                                offeringIdentifier: "base")
                    ]
                )],
            currentOfferingID: "base")
    }
}
