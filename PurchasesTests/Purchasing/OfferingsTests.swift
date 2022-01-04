//
//  OfferingsTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 Purchases. All rights reserved.
//

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class OfferingsTests: XCTestCase {

    let offeringsFactory = OfferingsFactory()

    func testPackageIsNotCreatedIfNoValidProducts() {
        let package = offeringsFactory.createPackage(with: [
            "identifier": "$rc_monthly",
            "platform_product_identifier": "com.myproduct.monthly"
        ], storeProductsByID: [
            "com.myproduct.annual": StoreProduct(sk1Product: SK1Product())
        ], offeringIdentifier: "offering")

        expect(package).to(beNil())
    }

    func testPackageIsCreatedIfValidProducts() throws {
        let productIdentifier = "com.myproduct.monthly"
        let product = MockSK1Product(mockProductIdentifier: productIdentifier)
        let packageIdentifier = "$rc_monthly"
        let package = try XCTUnwrap(
            offeringsFactory.createPackage(with: [
                "identifier": packageIdentifier,
                "platform_product_identifier": productIdentifier
            ], storeProductsByID: [
                productIdentifier: StoreProduct(sk1Product: product)
            ], offeringIdentifier: "offering")
        )

        expect(package.storeProduct.product).to(beAnInstanceOf(SK1StoreProduct.self))
        let sk1StoreProduct = try XCTUnwrap(package.storeProduct.product as? SK1StoreProduct)
        expect(sk1StoreProduct.underlyingSK1Product).to(equal(product))
        expect(package.identifier).to(equal(packageIdentifier))
        expect(package.packageType).to(equal(PackageType.monthly))
    }

    func testOfferingIsNotCreatedIfNoValidPackage() {
        let products = ["com.myproduct.bad": StoreProduct(sk1Product: SK1Product())]
        let offering = offeringsFactory.createOffering(from: products, offeringData: [
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
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct)
        ]
        let offeringIdentifier = "offering_a"
        let serverDescription = "This is the base offering"
        let offering = offeringsFactory.createOffering(from: products, offeringData: [
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

    func testListOfOfferingsIsNilIfNoValidOffering() {
        let offerings = offeringsFactory.createOfferings(from: [:], data: [
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
                ]
            ],
            "current_offering_id": "offering_a"
        ])

        expect(offerings).to(beNil())
    }

    func testOfferingsIsCreated() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct)
        ]
        let maybeOfferings = offeringsFactory.createOfferings(from: products, data: [
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
                ]
            ],
            "current_offering_id": "offering_a"
        ])

        let offerings = try XCTUnwrap(maybeOfferings)
        expect(offerings["offering_a"]).toNot(beNil())
        expect(offerings["offering_b"]).toNot(beNil())
        expect(offerings.current).to(be(offerings["offering_a"]))
    }

    func testLifetimePackage() throws {
        try testPackageType(packageType: PackageType.lifetime)
    }

    func testAnnualPackage() throws {
        try testPackageType(packageType: PackageType.annual)
    }

    func testSixMonthPackage() throws {
        try testPackageType(packageType: PackageType.sixMonth)
    }

    func testThreeMonthPackage() throws {
        try testPackageType(packageType: PackageType.threeMonth)
    }

    func testTwoMonthPackage() throws {
        try testPackageType(packageType: PackageType.twoMonth)
    }

    func testMonthlyPackage() throws {
        try testPackageType(packageType: PackageType.monthly)
    }

    func testWeeklyPackage() throws {
        try testPackageType(packageType: PackageType.weekly)
    }

    func testCustomPackage() throws {
        try testPackageType(packageType: PackageType.custom)
    }

    func testUnknownPackageType() throws {
        try testPackageType(packageType: PackageType.unknown)
    }

    func testOfferingsIsNilIfNoOfferingCanBeCreated() throws {
        let data = [
            "offerings": [],
            "current_offering_id": nil
        ]
        let maybeOfferings = offeringsFactory.createOfferings(from: [:], data: data as [String: Any])

        expect(maybeOfferings).to(beNil())
    }

    func testCurrentOfferingWithBrokenProductReturnsNilForCurrentOfferingButContainsOtherOfferings() throws {
        let storeProductsByID = [
            "com.myproduct.annual": StoreProduct(
                sk1Product: MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
            )
        ]

        let data: [String: Any] = [
            "offerings": [
                [
                    "identifier": "offering_a",
                    "description": "This is the base offering",
                    "packages": [
                        ["identifier": "$rc_six_month",
                         "platform_product_identifier": "com.myproduct.annual"]
                    ]
                ]
            ],
            "current_offering_id": "offering_with_broken_product"
        ]
        let maybeOfferings = offeringsFactory.createOfferings(from: storeProductsByID, data: data)

        let offerings = try XCTUnwrap(maybeOfferings)
        expect(offerings.current).to(beNil())
    }

    func testBadOfferingsDataReturnsNil() {
        let data = [:] as [String: Any]
        let offerings = offeringsFactory.createOfferings(from: [:], data: data as [String: Any])

        expect(offerings).to(beNil())
    }

}

private extension OfferingsTests {
    // swiftlint:disable:next function_body_length
    func testPackageType(packageType: PackageType) throws {
        var identifier = Package.string(from: packageType)
        if identifier == nil {
            if packageType == PackageType.unknown {
                identifier = "$rc_unknown_id_from_the_future"
            } else {
                identifier = "custom"
            }
        }
        let productIdentifier = "com.myproduct"
        let products = [
            productIdentifier: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: productIdentifier))
        ]
        let maybeOfferings = offeringsFactory.createOfferings(from: products, data: [
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

        let offerings = try XCTUnwrap(maybeOfferings)
        expect(offerings.current).toNot(beNil())
        if packageType == PackageType.lifetime {
            expect(offerings.current?.lifetime).toNot(beNil())
        } else {
            expect(offerings.current?.lifetime).to(beNil())
        }
        if packageType == PackageType.annual {
            expect(offerings.current?.annual).toNot(beNil())
        } else {
            expect(offerings.current?.annual).to(beNil())
        }
        if packageType == PackageType.sixMonth {
            expect(offerings.current?.sixMonth).toNot(beNil())
        } else {
            expect(offerings.current?.sixMonth).to(beNil())
        }
        if packageType == PackageType.threeMonth {
            expect(offerings.current?.threeMonth).toNot(beNil())
        } else {
            expect(offerings.current?.threeMonth).to(beNil())
        }
        if packageType == PackageType.twoMonth {
            expect(offerings.current?.twoMonth).toNot(beNil())
        } else {
            expect(offerings.current?.twoMonth).to(beNil())
        }
        if packageType == PackageType.monthly {
            expect(offerings.current?.monthly).toNot(beNil())
        } else {
            expect(offerings.current?.monthly).to(beNil())
        }
        if packageType == PackageType.weekly {
            expect(offerings.current?.weekly).toNot(beNil())
        } else {
            expect(offerings.current?.weekly).to(beNil())
        }
        let package = offerings["offering_a"]?.package(identifier: identifier)
        expect(package?.packageType).to(equal(packageType))
    }

}
