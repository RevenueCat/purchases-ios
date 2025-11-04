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

@_spi(Internal) @testable import RevenueCat

class OfferingsTests: TestCase {

    private let offeringsFactory = OfferingsFactory()

    func testPackageIsNotCreatedIfNoValidProducts() {
        let package = self.offeringsFactory.createPackage(
            with: .init(identifier: "$rc_monthly",
                        platformProductIdentifier: "com.myproduct.monthly",
                        webCheckoutUrl: nil),
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
                with: .init(identifier: packageIdentifier,
                            platformProductIdentifier: productIdentifier,
                            webCheckoutUrl: nil),
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
                    .init(identifier: "$rc_monthly",
                          platformProductIdentifier: "com.myproduct.monthly",
                          webCheckoutUrl: nil),
                    .init(identifier: "$rc_annual",
                          platformProductIdentifier: "com.myproduct.annual",
                          webCheckoutUrl: nil)
                ],
                webCheckoutUrl: nil),
            uiConfig: nil
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
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil),
                        .init(identifier: "$rc_annual",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil),
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.sixMonth",
                              webCheckoutUrl: nil)
                    ],
                    webCheckoutUrl: nil),
                uiConfig: nil
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
        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.sixMonth",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil),
                .init(identifier: "offering_b",
                      description: "This is the base offering b",
                      packages: [
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil)
            ],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        let offerings = self.offeringsFactory.createOfferings(
            from: [:],
            contents: Offerings.Contents(response: response,
                                         httpResponseSource: .mainServer)
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
        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil),
                .init(identifier: "offering_b",
                      description: "This is the base offering b",
                      packages: [
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil),
                        .init(identifier: "custom_package",
                              platformProductIdentifier: "com.myproduct.custom",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil)
            ],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                contents: Offerings.Contents(response: response,
                                             httpResponseSource: .mainServer)
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

    func testOfferingIdsByPlacementWithFallbackOffering() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let customProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.custom")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct),
            "com.myproduct.custom": StoreProduct(sk1Product: customProduct)
        ]
        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil)
                      ], webCheckoutUrl: nil),
                .init(identifier: "offering_b",
                      description: "This is the base offering b",
                      packages: [
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil),
                        .init(identifier: "custom_package",
                              platformProductIdentifier: "com.myproduct.custom",
                              webCheckoutUrl: nil)
                      ], webCheckoutUrl: nil),
                .init(identifier: "offering_c",
                      description: "This is the base offering b",
                      packages: [
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil),
                        .init(identifier: "custom_package",
                              platformProductIdentifier: "com.myproduct.custom",
                              webCheckoutUrl: nil)
                      ], webCheckoutUrl: nil)
            ],
            placements: .init(fallbackOfferingId: "offering_c",
                              offeringIdsByPlacement: .init(wrappedValue: [
                                "placement_name": "offering_b",
                                "placement_name_with_nil": nil
                              ])),
            targeting: .init(revision: 1, ruleId: "abc123"),
            uiConfig: nil
        )
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                contents: Offerings.Contents(response: response,
                                             httpResponseSource: .mainServer)
            )
        )

        let offeringA = try XCTUnwrap(offerings["offering_a"])
        let offeringB = try XCTUnwrap(offerings["offering_b"])
        let offeringC = try XCTUnwrap(offerings["offering_c"])

        let currentOfferingByPlacement = try XCTUnwrap(offerings.currentOffering(
            forPlacement: "placement_name")
        )
        let currentOfferingByPlacementContext = try XCTUnwrap(
            currentOfferingByPlacement.availablePackages.first?.presentedOfferingContext
        )

        let currentOfferingFallback = try XCTUnwrap(offerings.currentOffering(
            forPlacement: "unexisting_placement_name")
        )
        let currentOfferingFallbackContext = try XCTUnwrap(
            currentOfferingFallback.availablePackages.first?.presentedOfferingContext
        )

        expect(offerings.current?.identifier) == offeringA.identifier

        expect(currentOfferingByPlacement.identifier) == offeringB.identifier
        expect(currentOfferingByPlacementContext.offeringIdentifier) == offeringB.identifier
        expect(currentOfferingByPlacementContext.placementIdentifier) == "placement_name"
        expect(currentOfferingByPlacementContext.targetingContext!.revision) == 1
        expect(currentOfferingByPlacementContext.targetingContext!.ruleId) == "abc123"

        expect(currentOfferingFallback.identifier) == offeringC.identifier
        expect(currentOfferingFallbackContext.offeringIdentifier) == offeringC.identifier
        expect(currentOfferingFallbackContext.placementIdentifier) == "unexisting_placement_name"
        expect(currentOfferingFallbackContext.targetingContext!.revision) == 1
        expect(currentOfferingFallbackContext.targetingContext!.ruleId) == "abc123"

        expect(offerings.currentOffering(forPlacement: "placement_name_with_nil")).to(beNil())
    }

    func testOfferingIdsByPlacementWithNullFallbackOffering() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let customProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.custom")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct),
            "com.myproduct.custom": StoreProduct(sk1Product: customProduct)
        ]
        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil),
                .init(identifier: "offering_b",
                      description: "This is the base offering b",
                      packages: [
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil),
                        .init(identifier: "custom_package",
                              platformProductIdentifier: "com.myproduct.custom",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil)
            ],
            placements: .init(fallbackOfferingId: nil,
                              offeringIdsByPlacement: .init(wrappedValue: [
                                "placement_name": "offering_b",
                                "placement_name_with_nil": nil
                              ])),
            targeting: nil,
            uiConfig: nil
        )
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                contents: Offerings.Contents(response: response,
                                             httpResponseSource: .mainServer)
            )
        )

        let offeringA = try XCTUnwrap(offerings["offering_a"])
        let offeringB = try XCTUnwrap(offerings["offering_b"])
        expect(offerings.current) === offeringA
        expect(offerings.currentOffering(forPlacement: "placement_name")!.identifier) == offeringB.identifier
        expect(offerings.currentOffering(forPlacement: "placement_name_with_nil")).to(beNil())
        expect(offerings.currentOffering(forPlacement: "unexisting_placement_name")).to(beNil())
    }

    func testTargeting() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let customProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.custom")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct),
            "com.myproduct.custom": StoreProduct(sk1Product: customProduct)
        ]
        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil)
                      ], webCheckoutUrl: nil)
            ],
            placements: nil,
            targeting: .init(revision: 1, ruleId: "abc123"),
            uiConfig: nil
        )
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                contents: Offerings.Contents(response: response,
                                             httpResponseSource: .mainServer)
            )
        )

        let offeringA = try XCTUnwrap(offerings["offering_a"])

        // Current offering should have targeting context
        expect(offerings.current!.identifier) == offeringA.identifier
        expect(
            offerings.current!.availablePackages.first!.presentedOfferingContext.targetingContext!.revision
        ) == 1
        expect(
            offerings.current!.availablePackages.first!.presentedOfferingContext.targetingContext!.ruleId
        ) == "abc123"

        // Offering accessed directly (even if same as current) should not have targeting context
        expect(
            offerings.all.values.first!.availablePackages.first!.presentedOfferingContext.targetingContext
        ).to(beNil())
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
            ],
            "elements": [
                [
                    "number": 1
                ],
                [
                    "number": 2
                ]
            ],
            "element": [
                "number": 3
            ]
        ]

        let annualProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.annual")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.myproduct.monthly")
        let products = [
            "com.myproduct.annual": StoreProduct(sk1Product: annualProduct),
            "com.myproduct.monthly": StoreProduct(sk1Product: monthlyProduct)
        ]

        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil)
                      ],
                      metadata: .init(
                        wrappedValue: metadata
                      ),
                      webCheckoutUrl: nil),
                .init(identifier: "offering_b",
                      description: "This is the base offering b",
                      packages: [
                        .init(identifier: "$rc_monthly",
                              platformProductIdentifier: "com.myproduct.monthly",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil)
            ],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )

        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(
                from: products,
                contents: Offerings.Contents(response: response,
                                             httpResponseSource: .mainServer)
            )
        )

        expect(offerings["offering_a"]).toNot(beNil())
        expect(offerings["offering_b"]).toNot(beNil())
        expect(offerings.current) == offerings["offering_a"]

        let offeringA = try XCTUnwrap(offerings["offering_a"])
        expect(offeringA.metadata).to(haveCount(8))
        expect(offeringA.getMetadataValue(for: "int", default: 0)) == 5
        expect(offeringA.getMetadataValue(for: "double", default: 0.0)) == 5.5
        expect(offeringA.getMetadataValue(for: "boolean", default: false)) == true
        expect(offeringA.getMetadataValue(for: "string", default: "")) == "five"

        expect(offeringA.getMetadataValue(for: "pizza", default: "no pizza")) == "no pizza"

        let optionalInt: Int? = offeringA.getMetadataValue(for: "optionalInt", default: nil)
        expect(optionalInt).to(beNil())

        let wrongMetadataType = offeringA.getMetadataValue(for: "string", default: 5.5)
        expect(wrongMetadataType) == 5.5

        let intWithoutDefault: Int? = offeringA.getMetadataValue(for: "int")
        expect(intWithoutDefault) == 5

        let doubleWithoutDefault: Double? = offeringA.getMetadataValue(for: "double")
        expect(doubleWithoutDefault) == 5.5

        let boolWithoutDefault: Bool? = offeringA.getMetadataValue(for: "boolean")
        expect(boolWithoutDefault) == true

        let stringWithoutDefault: String? = offeringA.getMetadataValue(for: "string")
        expect(stringWithoutDefault) == "five"

        struct Data: Decodable, Equatable {
            var number: Int
        }

        let elements: [Data]? = offeringA.getMetadataValue(for: "elements")
        expect(elements) == [.init(number: 1), .init(number: 2)]

        let element: Data? = offeringA.getMetadataValue(for: "element")
        expect(element) == .init(number: 3)

        let missing: Data? = offeringA.getMetadataValue(for: "missing")
        expect(missing).to(beNil())

        do {
            let logger = TestLogHandler()

            expect(offeringA.getMetadataValue(for: "dictionary") as Data?)
                .to(beNil())

            logger.verifyMessageWasLogged("Error deserializing `Data`",
                                          level: .debug,
                                          expectedCount: 1)
        }

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
        let offerings = self.offeringsFactory.createOfferings(
            from: [:],
            contents: Offerings.Contents(response: offeringsResponse,
                                         httpResponseSource: .mainServer)
        )

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
                        .init(identifier: "$rc_six_month",
                              platformProductIdentifier: "com.myproduct.annual",
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil)
            ],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        let offerings = try XCTUnwrap(
            self.offeringsFactory.createOfferings(from: storeProductsByID,
                                                  contents: Offerings.Contents(response: response,
                                                                               httpResponseSource: .mainServer))
        )

        expect(offerings.current).to(beNil())
    }

    // MARK: - Offering from OfferingResponse.Offering

    func testCreateOfferingWithoutPaywall() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.yearly_10.99.2_week_intro")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro")
        let products = [
            "com.revenuecat.yearly_10.99.2_week_intro": StoreProduct(sk1Product: annualProduct),
            "com.revenuecat.monthly_4.99.1_week_intro": StoreProduct(sk1Product: monthlyProduct)
        ]

        let offeringResponse: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("Offerings")
        let offeringResponse0 = try XCTUnwrap(offeringResponse.offerings[safe: 0])

        expect(offeringResponse0.identifier) == "default"
        expect(offeringResponse0.description) == "standard set of packages"

        let uiConfig: UIConfig = try XCTUnwrap(BaseHTTPResponseTest.decodeFixture("UIConfig"))

        let offering = try XCTUnwrap(
            self.offeringsFactory.createOffering(from: products,
                                                 offering: offeringResponse0,
                                                 uiConfig: uiConfig)
            )

        expect(offering.paywall).to(beNil())
        expect(offering.paywallComponents).to(beNil())
        expect(offering.draftPaywallComponents).to(beNil())
        expect(offering.hasPaywall) == false
    }

    func testCreateOfferingWithPaywallData() throws {
        let annualProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.yearly_10.99.2_week_intro")
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro")
        let products = [
            "com.revenuecat.yearly_10.99.2_week_intro": StoreProduct(sk1Product: annualProduct),
            "com.revenuecat.monthly_4.99.1_week_intro": StoreProduct(sk1Product: monthlyProduct)
        ]

        let offeringResponse: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("Offerings")
        let offeringResponse0 = try XCTUnwrap(offeringResponse.offerings[safe: 2])

        expect(offeringResponse0.identifier) == "paywall"
        expect(offeringResponse0.description) == "Offering with paywall"

        let uiConfig: UIConfig = try XCTUnwrap(BaseHTTPResponseTest.decodeFixture("UIConfig"))

        let offering = try XCTUnwrap(
            self.offeringsFactory.createOffering(from: products,
                                                 offering: offeringResponse0,
                                                 uiConfig: uiConfig)
            )

        expect(offering.paywall).toNot(beNil())
        expect(offering.paywallComponents).to(beNil())
        expect(offering.draftPaywallComponents).to(beNil())
        expect(offering.hasPaywall) == true
    }

    func testCreateOfferingWithPaywallComponents() throws {
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro")
        let products = [
            "com.revenuecat.monthly_4.99.1_week_intro": StoreProduct(sk1Product: monthlyProduct)
        ]

        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let offeringResponse0 = try XCTUnwrap(offeringResp.offerings[safe: 0])

        expect(offeringResponse0.identifier) == "paywall_components"
        expect(offeringResponse0.description) == "Offering with paywall components"

        let uiConfig: UIConfig = try XCTUnwrap(BaseHTTPResponseTest.decodeFixture("UIConfig"))

        let offering = try XCTUnwrap(
            self.offeringsFactory.createOffering(from: products,
                                                 offering: offeringResponse0,
                                                 uiConfig: uiConfig)
            )

        expect(offering.paywall).to(beNil())
        expect(offering.paywallComponents).toNot(beNil())
        expect(offering.draftPaywallComponents).to(beNil())
        expect(offering.hasPaywall) == true
    }

    func testCreateOfferingWithPaywallComponentsAndDraftPaywallComponents() throws {
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro")
        let products = [
            "com.revenuecat.monthly_4.99.1_week_intro": StoreProduct(sk1Product: monthlyProduct)
        ]

        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let offeringResponse0 = try XCTUnwrap(offeringResp.offerings[safe: 1])

        expect(offeringResponse0.identifier) == "paywall_components_with_draft"
        expect(offeringResponse0.description) == "Offering with paywall components + draft paywall"

        let uiConfig: UIConfig = try XCTUnwrap(BaseHTTPResponseTest.decodeFixture("UIConfig"))

        let offering = try XCTUnwrap(
            self.offeringsFactory.createOffering(from: products,
                                                 offering: offeringResponse0,
                                                 uiConfig: uiConfig)
            )

        expect(offering.paywall).to(beNil())
        expect(offering.paywallComponents).toNot(beNil())
        expect(offering.draftPaywallComponents).toNot(beNil())
        expect(offering.hasPaywall) == true
    }

    func testCreateOfferingWithOnlyDraftPaywallComponents() throws {
        let monthlyProduct = MockSK1Product(mockProductIdentifier: "com.revenuecat.monthly_4.99.1_week_intro")
        let products = [
            "com.revenuecat.monthly_4.99.1_week_intro": StoreProduct(sk1Product: monthlyProduct)
        ]

        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let offeringResponse0 = try XCTUnwrap(offeringResp.offerings[safe: 2])

        expect(offeringResponse0.identifier) == "only_draft_paywall_components"
        expect(offeringResponse0.description) == "Offering with only draft paywall"

        let uiConfig: UIConfig = try XCTUnwrap(BaseHTTPResponseTest.decodeFixture("UIConfig"))

        let offering = try XCTUnwrap(
            self.offeringsFactory.createOffering(from: products,
                                                 offering: offeringResponse0,
                                                 uiConfig: uiConfig)
            )

        expect(offering.paywall).to(beNil())
        expect(offering.paywallComponents).to(beNil())
        expect(offering.draftPaywallComponents).toNot(beNil())
        expect(offering.hasPaywall) == false
    }

    // MARK: - Offerings.Contents

    func testOfferingsContentsInitFromMainServer() throws {
        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let contents = Offerings.Contents(response: offeringResp,
                                          httpResponseSource: .mainServer)
        expect(contents.originalSource) == .main
        expect(contents.loadedFromCache) == false
    }

    func testOfferingsContentsInitFromFallbackUrl() throws {
        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let contents = Offerings.Contents(response: offeringResp,
                                          httpResponseSource: .fallbackUrl)
        expect(contents.originalSource) == .fallbackUrl
        expect(contents.loadedFromCache) == false
    }

    func testOfferingsContentsInitFromLoadShedder() throws {
        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let contents = Offerings.Contents(response: offeringResp,
                                          httpResponseSource: .loadShedder)
        expect(contents.originalSource) == .loadShedder
        expect(contents.loadedFromCache) == false
    }

    func testOfferingsContentsCopyWithLoadedFromCache() throws {
        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let contents = Offerings.Contents(response: offeringResp,
                                          httpResponseSource: .mainServer)
        expect(contents.loadedFromCache) == false

        let copyFromCache = contents.copyWithLoadedFromCache()
        expect(copyFromCache.loadedFromCache) == true
    }

    func testOfferingsContentsCopyWithLoadedFromCacheIsIdempotent() throws {
        let offeringResp: OfferingsResponse = try BaseHTTPResponseTest.decodeFixture("OfferingsWithPaywallComponents")
        let contents = Offerings.Contents(response: offeringResp,
                                          httpResponseSource: .mainServer)
        expect(contents.loadedFromCache) == false

        let copyFromCache = contents.copyWithLoadedFromCache()
        let copyFromCache2 = copyFromCache.copyWithLoadedFromCache()
        let copyFromCache3 = copyFromCache2.copyWithLoadedFromCache()

        expect(copyFromCache3.loadedFromCache) == true
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
        let response = OfferingsResponse(
            currentOfferingId: "offering_a",
            offerings: [
                .init(identifier: "offering_a",
                      description: "This is the base offering",
                      packages: [
                        .init(identifier: identifier,
                              platformProductIdentifier: productIdentifier,
                              webCheckoutUrl: nil)
                      ],
                      webCheckoutUrl: nil)
            ],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        let offerings = try XCTUnwrap(
            offeringsFactory.createOfferings(
                from: products,
                contents: Offerings.Contents(response: response,
                                             httpResponseSource: .mainServer)
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
