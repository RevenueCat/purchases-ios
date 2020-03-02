//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockOfferingsFactory: RCOfferingsFactory {

    var emptyOfferings = false
    var badOfferings = false

    override func createOfferings(withProducts products: [String: SKProduct],
                                  data: [AnyHashable: Any]) -> Purchases.Offerings? {
        if (emptyOfferings) {
            return Purchases.Offerings(offerings: [:], currentOfferingID: "base")
        }
        if (badOfferings) {
            return nil
        }
        return Purchases.Offerings(
            offerings: [
                "base": Purchases.Offering(
                    identifier: "base",
                    serverDescription: "This is the base offering",
                    availablePackages: [
                        Purchases.Package(identifier: "$rc_monthly",
                                          packageType: Purchases.PackageType.monthly,
                                          product: MockProduct(mockProductIdentifier: "monthly_freetrial"),
                                          offeringIdentifier: "base")
                    ]
                )],
            currentOfferingID: "base")
    }
}
