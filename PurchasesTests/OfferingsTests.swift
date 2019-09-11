//
//  OfferingsTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble

import Purchases

class MockSKProduct: SKProduct {

    var mockIdentifier: String?
    override var productIdentifier: String {
        get {
            return mockIdentifier!
        }
    }

    init(mockIdentifier: String?) {
        self.mockIdentifier = mockIdentifier
        super.init()
    }
}


class OfferingsTests: XCTestCase {

    func testPackageIsNotCreatedIfNoValidProducts() {
        let package = RCOfferingsFactory.createPackage(withData: [
            "identifier": "$rc_monthly",
            "platform_product_identifier": "com.myproduct.monthly"
        ], products: [
            "com.myproduct.annual": SKProduct()
        ])

        expect(package).to(beNil())
    }

    func testPackageIsCreatedIfValidProducts() {
        let productIdentifier = "com.myproduct.monthly"
        let product = MockSKProduct(mockIdentifier: productIdentifier)
        let packageIdentifier = "$rc_monthly"
        let package = RCOfferingsFactory.createPackage(withData: [
            "identifier": packageIdentifier,
            "platform_product_identifier": productIdentifier
        ], products: [
            productIdentifier: product
        ])

        expect(package).toNot(beNil())
        expect(package?.product).to(equal(product))
        expect(package?.identifier).to(equal(packageIdentifier))
        expect(package?.packageType).to(equal(PackageType.monthly))
    }

    func testOfferingIsNotCreatedIfNoValidPackage() {
        let products = ["com.myproduct.bad": SKProduct()]
        let offering = RCOfferingsFactory.createOffering(withProducts: products, offeringData: [
            "identifier": "offering_a",
            "description": "This is the base offering",
            "packages": [
                ["identifier": "$rc_monthly",
                 "platform_product_identifier": "com.myproduct.monthly"],
                ["identifier": "$rc_annual",
                 "platform_product_identifier": "com.myproduct.annual"]
            ]
        ])

        expect(offering).to(beNil())
    }

    func testOfferingIsCreatedIfValidPackages() {
        let products = [
            "com.myproduct.annual": MockSKProduct(mockIdentifier: "com.myproduct.annual"),
            "com.myproduct.monthly": MockSKProduct(mockIdentifier: "com.myproduct.monthly")
        ]
        let offeringIdentifier = "offering_a"
        let serverDescription = "This is the base offering"
        let offering = RCOfferingsFactory.createOffering(withProducts: products, offeringData: [
            "identifier": offeringIdentifier,
            "description": serverDescription,
            "packages": [
                ["identifier": "$rc_monthly",
                 "platform_product_identifier": "com.myproduct.monthly"],
                ["identifier": "$rc_annual",
                 "platform_product_identifier": "com.myproduct.annual"],
                ["identifier": "$rc_six_month",
                 "platform_product_identifier": "com.myproduct.sixMonth"]
            ]
        ])
        expect(offering).toNot(beNil())
        expect(offering?.identifier).to(equal(offeringIdentifier))
        expect(offering?.serverDescription).to(equal(serverDescription))
        expect(offering?.availablePackages.count).to(be(2))
        expect(offering?.monthly).toNot(beNil())
        expect(offering?.annual).toNot(beNil())
        expect(offering?.sixMonth).to(beNil())
    }

    func testListOfOfferingsIsEmptyIfNoValidOffering() {
        let offerings = RCOfferingsFactory.createOfferings(withProducts: [:], data: [
            "offerings": [
                [
                    "identifier": "offering_a",
                    "description": "This is the base offering",
                    "packages": [
                        ["identifier": "$rc_six_month",
                         "platform_product_identifier": "com.myproduct.sixMonth"]
                    ]
                ],
                [
                    "identifier": "offering_b",
                    "description": "This is the base offering b",
                    "packages": [
                        ["identifier": "$rc_monthly",
                         "platform_product_identifier": "com.myproduct.monthly"]
                    ]
                ],
            ],
            "current_offering_id": "offering_a"
        ])

        expect(offerings).toNot(beNil())
        expect(offerings.current).to(beNil())
        expect(offerings["offering_a"]).to(beNil())
        expect(offerings["offering_b"]).to(beNil())
    }

    func testOfferingsIsCreated() {
        let products = [
            "com.myproduct.annual": MockSKProduct(mockIdentifier: "com.myproduct.annual"),
            "com.myproduct.monthly": MockSKProduct(mockIdentifier: "com.myproduct.monthly")
        ]
        let offerings = RCOfferingsFactory.createOfferings(withProducts: products, data: [
            "offerings": [
                [
                    "identifier": "offering_a",
                    "description": "This is the base offering",
                    "packages": [
                        ["identifier": "$rc_six_month",
                         "platform_product_identifier": "com.myproduct.annual"]
                    ]
                ],
                [
                    "identifier": "offering_b",
                    "description": "This is the base offering b",
                    "packages": [
                        ["identifier": "$rc_monthly",
                         "platform_product_identifier": "com.myproduct.monthly"]
                    ]
                ],
            ],
            "current_offering_id": "offering_a"
        ])

        expect(offerings).toNot(beNil())
        expect(offerings["offering_a"]).toNot(beNil())
        expect(offerings["offering_b"]).toNot(beNil())
        expect(offerings.current).to(be(offerings["offering_a"]))
    }

    func testLifetimePackage() {
        testPackageType(packageType: PackageType.lifetime)
    }

    func testAnnualPackage() {
        testPackageType(packageType: PackageType.annual)
    }

    func testSixMonthPackage() {
        testPackageType(packageType: PackageType.sixMonth)
    }

    func testThreeMonthPackage() {
        testPackageType(packageType: PackageType.threeMonth)
    }

    func testTwoMonthPackage() {
        testPackageType(packageType: PackageType.twoMonth)
    }

    func testMonthlyPackage() {
        testPackageType(packageType: PackageType.monthly)
    }

    func testWeeklyPackage() {
        testPackageType(packageType: PackageType.weekly)
    }

    func testCustomPackage() {
        testPackageType(packageType: PackageType.custom)
    }

    private func testPackageType(packageType: PackageType) {
        var identifier: String {
            switch (packageType) {
            case .lifetime:
                return "$rc_lifetime"
            case .custom:
                return "custom"
            case .annual:
                return "$rc_annual"
            case .sixMonth:
                return "$rc_six_month"
            case .threeMonth:
                return "$rc_three_month"
            case .twoMonth:
                return "$rc_two_month"
            case .monthly:
                return "$rc_monthly"
            case .weekly:
                return "$rc_weekly"
            }
        }
        let productIdentifier = "com.myproduct"
        let products = [
            productIdentifier: MockSKProduct(mockIdentifier: productIdentifier)
        ]
        let offerings = RCOfferingsFactory.createOfferings(withProducts: products, data: [
            "offerings": [
                [
                    "identifier": "offering_a",
                    "description": "This is the base offering",
                    "packages": [
                        ["identifier": identifier,
                         "platform_product_identifier": "com.myproduct"]
                    ]
                ]
            ],
            "current_offering_id": "offering_a"
        ])

        expect(offerings).toNot(beNil())
        expect(offerings.current).toNot(beNil())
        if (packageType == PackageType.lifetime) {
            expect(offerings.current.lifetime).toNot(beNil())
        } else {
            expect(offerings.current.lifetime).to(beNil())
        }
        if (packageType == PackageType.annual) {
            expect(offerings.current.annual).toNot(beNil())
        } else {
            expect(offerings.current.annual).to(beNil())
        }
        if (packageType == PackageType.sixMonth) {
            expect(offerings.current.sixMonth).toNot(beNil())
        } else {
            expect(offerings.current.sixMonth).to(beNil())
        }
        if (packageType == PackageType.threeMonth) {
            expect(offerings.current.threeMonth).toNot(beNil())
        } else {
            expect(offerings.current.threeMonth).to(beNil())
        }
        if (packageType == PackageType.twoMonth) {
            expect(offerings.current.twoMonth).toNot(beNil())
        } else {
            expect(offerings.current.twoMonth).to(beNil())
        }
        if (packageType == PackageType.monthly) {
            expect(offerings.current.monthly).toNot(beNil())
        } else {
            expect(offerings.current.monthly).to(beNil())
        }
        if (packageType == PackageType.weekly) {
            expect(offerings.current.weekly).toNot(beNil())
        } else {
            expect(offerings.current.weekly).to(beNil())
        }
        let package = offerings["offering_a"]?.package(identifier: identifier)
        expect(package?.packageType).to(equal(packageType))
    }

}
