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

class OfferingsTests: TestCase {

    private let offeringsFactory = OfferingsFactory()

    func testPackageIsNotCreatedIfNoValidProducts() {
        let package = self.offeringsFactory.createPackage(
            with: .init(identifier: "$rc_monthly", platformProductIdentifier: "com.myproduct.monthly"),
            productsByID: [
                "com.myproduct.annual": StoreProduct(sk1Product: SK1Product())
            ],
            offeringIdentifier: "offering"
        )

        expect(package).to(beNil())
    }

    func testPackageIsCreatedIfValidProducts() throws {
        let productIdentifier = "com.myproduct.monthly"
        let product = MockSK1Product(mockProductIdentifier: productIdentifier)
        let packageIdentifier = "$rc_monthly"
        let package = try XCTUnwrap(
            self.offeringsFactory.createPackage(
                with: .init(identifier: packageIdentifier, platformProductIdentifier: productIdentifier),
                productsByID: [
                    productIdentifier: StoreProduct(sk1Product: product)
                ],
                offeringIdentifier: "offering"
            )
        )

        expect(package.storeProduct.product).to(beAnInstanceOf(SK1StoreProduct.self))
        let sk1StoreProduct = try XCTUnwrap(package.storeProduct.product as? SK1StoreProduct)
        expect(sk1StoreProduct.underlyingSK1Product).to(equal(product))
        expect(package.identifier) == packageIdentifier
        expect(package.packageType) == PackageType.monthly
    }

    func testOfferingIsNotCreatedIfNoValidPackage() {
        let products = ["com.myproduct.bad": StoreProduct(sk1Product: SK1Product())]
        let offering = self.offeringsFactory.createOffering(
            from: products,
            offering: .init(
                identifier: "offering_a",
                description: "This is the base offering",
                packages: [
                    .init(identifier: "$rc_monthly", platformProductIdentifier: "com.myproduct.monthly"),
                    .init(identifier: "$rc_annual", platformProductIdentifier: "com.myproduct.annual")
                ])
        )

        expect(offering).to(beNil())
    }

    func testOfferingIsCreatedIfValidPackages() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct)
        ]
        let offeringIdentifier = "offering_a"
        let serverDescription = "This is the base offering"
        let offering = try XCTUnwrap(
            self.offeringsFactory.createOffering(
                from: products,
                offering: .init(
                    identifier: offeringIdentifier,
                    description: serverDescription,
                    packages: [
                        .init(identifier: "$rc_monthly", platformProductIdentifier: "com.myproduct.monthly"),
                        .init(identifier: "$rc_annual", platformProductIdentifier: "com.myproduct.annual"),
                        .init(identifier: "$rc_six_month", platformProductIdentifier: "com.myproduct.sixMonth")
                    ])
            )
        )

        expect(offering.identifier) == offeringIdentifier
        expect(offering.serverDescription) == serverDescription
        expect(offering.availablePackages).to(haveCount(2))
        expect(offering.monthly).toNot(beNil())
        expect(offering.annual).toNot(beNil())
        expect(offering.sixMonth).to(beNil())
    }

    func testListOfOfferingsIsNilIfNoValidOffering() {
        let offerings = self.offeringsFactory.createOfferings(
            from: [:],
            data: .init(
                currentOfferingId: "offering_a",
                offerings: [
                    .init(identifier: "offering_a",
                          description: "This is the base offering",
                          packages: [
                            .init(identifier: "$rc_six_month", platformProductIdentifier: "com.myproduct.sixMonth")
                          ]),
                    .init(identifier: "offering_b",
                          description: "This is the base offering b",
                          packages: [
                            .init(identifier: "$rc_monthly", platformProductIdentifier: "com.myproduct.monthly")
                          ])
                ]
            )
        )

        expect(offerings).to(beNil())
    }

    func testOfferingsIsCreated() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let customProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.custom")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct),
            "com.myproduct.custom": StoreProduct(sk1Product: customProduct)
        ]
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                data: .init(
                    currentOfferingId: "offering_a",
                    offerings: [
                        .init(identifier: "offering_a",
                              description: "This is the base offering",
                              packages: [
                                .init(identifier: "$rc_six_month", platformProductIdentifier: "com.myproduct.annual")
                              ]),
                        .init(identifier: "offering_b",
                              description: "This is the base offering b",
                              packages: [
                                .init(identifier: "$rc_monthly", platformProductIdentifier: "com.myproduct.monthly"),
                                .init(identifier: "custom_package", platformProductIdentifier: "com.myproduct.custom")
                              ])
                    ]
                )
            )
        )

        let offeringA = try XCTUnwrap(offerings["offering_a"])
        let offeringB = try XCTUnwrap(offerings["offering_b"])
        expect(offerings.current) === offeringA

        expect(offeringA.availablePackages).to(haveCount(1))
        expect(offeringA.availablePackages.first?.packageType) == .sixMonth

        expect(offeringB.availablePackages).to(haveCount(2))
        expect(offeringB.availablePackages[safe: 0]?.identifier) == PackageType.monthly.description
        expect(offeringB.availablePackages[safe: 0]?.packageType) == .monthly
        expect(offeringB.availablePackages[safe: 1]?.identifier) == "custom_package"
        expect(offeringB.availablePackages[safe: 1]?.packageType) == .custom
    }

    func testOfferingsWithMetadataIsCreated() throws {
        let metadata: [String: AnyDecodable] = [
            "int": 5,
            "double": 5.5,
            "boolean": true,
            "string": "five",
            "array": ["five"],
            "dictionary": [
                "string": "five"
            ]
        ]

        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct)
        ]
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                data: .init(
                    currentOfferingId: "offering_a",
                    offerings: [
                        .init(identifier: "offering_a",
                              description: "This is the base offering",
                              packages: [
                                .init(identifier: "$rc_six_month", platformProductIdentifier: "com.myproduct.annual")
                              ],
                              metadata: .init(
                                wrappedValue: metadata
                              )),
                        .init(identifier: "offering_b",
                              description: "This is the base offering b",
                              packages: [
                                .init(identifier: "$rc_monthly", platformProductIdentifier: "com.myproduct.monthly")
                              ])
                    ]
                )
            )
        )

        expect(offerings["offering_a"]).toNot(beNil())
        expect(offerings["offering_b"]).toNot(beNil())
        expect(offerings.current) == offerings["offering_a"]

        let offeringA = try XCTUnwrap(offerings["offering_a"])
        expect(offeringA.metadata).to(haveCount(6))
        expect(offeringA.getMetadataValue(for: "int", default: 0)) == 5
        expect(offeringA.getMetadataValue(for: "double", default: 0.0)) == 5.5
        expect(offeringA.getMetadataValue(for: "boolean", default: false)) == true
        expect(offeringA.getMetadataValue(for: "string", default: "")) == "five"

        expect(offeringA.getMetadataValue(for: "pizza", default: "no pizza")) == "no pizza"

        let optionalInt: Int? = offeringA.getMetadataValue(for: "optionalInt", default: nil)
        expect(optionalInt).to(beNil())

        let wrongMetadataType = offeringA.getMetadataValue(for: "string", default: 5.5)
        expect(wrongMetadataType) == 5.5
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

    @available(iOS 11.2, macCatalyst 13.0, tvOS 11.2, macOS 10.13.2, *)
    func testCustomNonSubscriptionPackage() throws {
        let sk1Product = MockSK1Product(mockProductIdentifier: "com.myProduct")
        sk1Product.mockSubscriptionPeriod = nil

        try testPackageType(packageType: PackageType.custom,
                            product: StoreProduct(sk1Product: sk1Product))
    }

    func testUnknownPackageType() throws {
        try testPackageType(packageType: PackageType.unknown)
    }

    func testOfferingsIsNilIfNoOfferingCanBeCreated() throws {
        let json = """
        {
            "offerings": [],
            "current_offering_id": null
        }
        """.asData

        let offeringsResponse: OfferingsResponse = try JSONDecoder.default.decode(jsonData: json)
        let offerings = self.offeringsFactory.createOfferings(from: [:], data: offeringsResponse)

        expect(offerings).to(beNil())
    }

    func testCurrentOfferingWithBrokenProductReturnsNilForCurrentOfferingButContainsOtherOfferings() throws {
        let storeProductsByID = [
            "com.myproduct.annual": StoreProduct(
                sk1Product: MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
            )
        ]

        let response: OfferingsResponse = .init(
            currentOfferingId: "offering_with_broken_product",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month", platformProductIdentifier: "com.myproduct.annual")
                      ])
            ]
        )
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(from: storeProductsByID, data: response)
        )

        expect(offerings.current).to(beNil())
    }

}

private extension OfferingsTests {

    func testPackageType(packageType: PackageType, product: StoreProduct? = nil) throws {
        let defaultIdentifier: String = {
            if packageType == PackageType.unknown {
                return "$rc_unknown_id_from_the_future"
            } else {
                return "custom"
            }
        }()

        let identifier = Package.string(from: packageType) ?? defaultIdentifier
        let productIdentifier = product?.productIdentifier ?? "com.myproduct"
        let products = [
            productIdentifier: product
            ?? StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: productIdentifier))
        ]
        let offerings = try XCTUnwrap(
            offeringsFactory.createOfferings(
                from: products,
                data: .init(
                    currentOfferingId: "offering_a",
                    offerings: [
                        .init(identifier: "offering_a",
                              description: "This is the base offering",
                              packages: [
                                .init(identifier: identifier, platformProductIdentifier: productIdentifier)
                              ])
                    ]
                )
            )
        )

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
        expect(package?.packageType) == packageType
    }

}
