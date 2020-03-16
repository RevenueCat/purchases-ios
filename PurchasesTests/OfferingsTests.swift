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

class OfferingsTests: XCTestCase {

    let offeringsFactory = RCOfferingsFactory()

    func testPackageIsNotCreatedIfNoValidProducts() {
        let package = offeringsFactory.createPackage(withData: [
            "identifier": "$rc_monthly",
            "platform_product_identifier": "com.myproduct.monthly"
        ], products: [
            "com.myproduct.annual": SKProduct()
        ], offeringIdentifier: "offering")

        expect(package).to(beNil())
    }

    func testPackageIsCreatedIfValidProducts() {
        let productIdentifier = "com.myproduct.monthly"
        let product = MockSKProduct(mockIdentifier: productIdentifier)
        let packageIdentifier = "$rc_monthly"
        let package = offeringsFactory.createPackage(withData: [
            "identifier": packageIdentifier,
            "platform_product_identifier": productIdentifier
        ], products: [
            productIdentifier: product
        ], offeringIdentifier: "offering")

        expect(package).toNot(beNil())
        expect(package?.product).to(equal(product))
        expect(package?.identifier).to(equal(packageIdentifier))
        expect(package?.packageType).to(equal(Purchases.PackageType.monthly))
    }

    func testOfferingIsNotCreatedIfNoValidPackage() {
        let products = ["com.myproduct.bad": SKProduct()]
        let offering = offeringsFactory.createOffering(withProducts: products, offeringData: [
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
        let offering = offeringsFactory.createOffering(withProducts: products, offeringData: [
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
        let offerings = offeringsFactory.createOfferings(withProducts: [:], data: [
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
        expect(offerings?.current).to(beNil())
        expect(offerings?["offering_a"]).to(beNil())
        expect(offerings?["offering_b"]).to(beNil())
    }

    func testOfferingsIsCreated() {
        let products = [
            "com.myproduct.annual": MockSKProduct(mockIdentifier: "com.myproduct.annual"),
            "com.myproduct.monthly": MockSKProduct(mockIdentifier: "com.myproduct.monthly")
        ]
        let offerings = offeringsFactory.createOfferings(withProducts: products, data: [
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
        expect(offerings!["offering_a"]).toNot(beNil())
        expect(offerings!["offering_b"]).toNot(beNil())
        expect(offerings!.current).to(be(offerings!["offering_a"]))
    }

    func testLifetimePackage() {
        testPackageType(packageType: Purchases.PackageType.lifetime)
    }

    func testAnnualPackage() {
        testPackageType(packageType: Purchases.PackageType.annual)
    }

    func testSixMonthPackage() {
        testPackageType(packageType: Purchases.PackageType.sixMonth)
    }

    func testThreeMonthPackage() {
        testPackageType(packageType: Purchases.PackageType.threeMonth)
    }

    func testTwoMonthPackage() {
        testPackageType(packageType: Purchases.PackageType.twoMonth)
    }

    func testMonthlyPackage() {
        testPackageType(packageType: Purchases.PackageType.monthly)
    }

    func testWeeklyPackage() {
        testPackageType(packageType: Purchases.PackageType.weekly)
    }

    func testCustomPackage() {
        testPackageType(packageType: Purchases.PackageType.custom)
    }

    func testUnknownPackageType() {
        testPackageType(packageType: Purchases.PackageType.unknown)
    }

    func testNoOfferings() {
        let data = [
            "offerings": [],
            "current_offering_id": nil
        ]
        let offerings = offeringsFactory.createOfferings(withProducts: [:], data: data as [AnyHashable : Any])

        expect(offerings).toNot(beNil())
        expect(offerings!.current).to(beNil())
    }

    func testCurrentOfferingWithBrokenProduct() {
        let data = [
            "offerings": [],
            "current_offering_id": "offering_with_broken_product"
        ] as [String : Any]
        let offerings = offeringsFactory.createOfferings(withProducts: [:], data: data as [AnyHashable : Any])

        expect(offerings).toNot(beNil())
        expect(offerings!.current).to(beNil())
    }

    func testBadOfferingsDataReturnsNil() {
        let data = [:] as [String : Any]
        let offerings = offeringsFactory.createOfferings(withProducts: [:], data: data as [AnyHashable : Any])

        expect(offerings).to(beNil())
    }

    private func testPackageType(packageType: Purchases.PackageType) {
        var identifier = Purchases.Package.string(from: packageType)
        if (identifier == nil) {
            if (packageType == Purchases.PackageType.unknown) {
                identifier = "$rc_unknown_id_from_the_future"
            } else {
                identifier = "custom"
            }
        }
        let productIdentifier = "com.myproduct"
        let products = [
            productIdentifier: MockSKProduct(mockIdentifier: productIdentifier)
        ]
        let offerings = offeringsFactory.createOfferings(withProducts: products, data: [
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
        expect(offerings!.current).toNot(beNil())
        if (packageType == Purchases.PackageType.lifetime) {
            expect(offerings!.current?.lifetime).toNot(beNil())
        } else {
            expect(offerings!.current?.lifetime).to(beNil())
        }
        if (packageType == Purchases.PackageType.annual) {
            expect(offerings!.current?.annual).toNot(beNil())
        } else {
            expect(offerings!.current?.annual).to(beNil())
        }
        if (packageType == Purchases.PackageType.sixMonth) {
            expect(offerings!.current?.sixMonth).toNot(beNil())
        } else {
            expect(offerings!.current?.sixMonth).to(beNil())
        }
        if (packageType == Purchases.PackageType.threeMonth) {
            expect(offerings!.current?.threeMonth).toNot(beNil())
        } else {
            expect(offerings!.current?.threeMonth).to(beNil())
        }
        if (packageType == Purchases.PackageType.twoMonth) {
            expect(offerings!.current?.twoMonth).toNot(beNil())
        } else {
            expect(offerings!.current?.twoMonth).to(beNil())
        }
        if (packageType == Purchases.PackageType.monthly) {
            expect(offerings!.current?.monthly).toNot(beNil())
        } else {
            expect(offerings!.current?.monthly).to(beNil())
        }
        if (packageType == Purchases.PackageType.weekly) {
            expect(offerings!.current?.weekly).toNot(beNil())
        } else {
            expect(offerings!.current?.weekly).to(beNil())
        }
        let package = offerings!["offering_a"]?.package(identifier: identifier)
        expect(package?.packageType).to(equal(packageType))
    }

}
