//
//  PackageFilteringTests.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class PackageFilteringTests: TestCase {

    func testFilterNoPackages() {
        expect(PaywallData.filter(packages: [], with: [.monthly])) == []
    }

    func testFilterPackagesWithEmptyList() {
        expect(PaywallData.filter(packages: [Self.monthly], with: [])) == []
    }

    func testFilterOutSinglePackge() {
        expect(PaywallData.filter(packages: [Self.monthly], with: [.annual])) == []
    }

    func testFilterOutNonSubscriptions() {
        expect(PaywallData.filter(packages: [Self.consumable], with: [.custom])) == []
    }

    func testFilterByPackageType() {
        expect(PaywallData.filter(packages: [Self.monthly, Self.annual], with: [.monthly])) == [Self.monthly]
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension PackageFilteringTests {

    static let monthly = Package(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: TestData.productWithIntroOffer.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
    static let annual = Package(
        identifier: "annual",
        packageType: .annual,
        storeProduct: TestData.productWithNoIntroOffer.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )

    static let consumable = Package(
        identifier: "consumable",
        packageType: .custom,
        storeProduct: consumableProduct.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )

    private static let consumableProduct = TestStoreProduct(
        localizedTitle: "Coins",
        price: 199.99,
        localizedPriceString: "$199.99",
        productIdentifier: "com.revenuecat.coins",
        productType: .consumable,
        localizedDescription: "Coins"
    )

    private static let offeringIdentifier = "offering"

}
