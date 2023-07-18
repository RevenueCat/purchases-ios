//
//  TemplateViewConfigurationTests.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class BaseTemplateViewConfigurationTests: TestCase {}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class TemplateViewConfigurationCreationTests: BaseTemplateViewConfigurationTests {

    private typealias Config = TemplateViewConfiguration.PackageConfiguration

    func testCreateWithNoPackages() {
        expect {
            try Config.create(
                with: [],
                filter: [.monthly],
                localization: TestData.paywallWithIntroOffer.localizedConfiguration,
                setting: .single
            )
        }.to(throwError(TemplateError.noPackages))
    }

    func testCreateWithNoFilter() {
        expect {
            try Config.create(
                with: [Self.monthly],
                filter: [],
                localization: TestData.paywallWithIntroOffer.localizedConfiguration,
                setting: .single
            )
        }.to(throwError(TemplateError.emptyPackageList))
    }

    func testCreateSinglePackage() throws {
        let result = try Config.create(
            with: [Self.monthly],
            filter: [.monthly],
            localization: Self.localization,
            setting: .single
        )

        switch result {
        case let .single(package):
            expect(package.content) === Self.monthly
            Self.verifyLocalizationWasProcessed(package.localization, for: Self.monthly)
        case .multiple:
            fail("Invalid result: \(result)")
        }
    }

    func testCreateMultiplePackage() throws {
        let result = try Config.create(
            with: [Self.monthly, Self.annual, Self.weekly],
            filter: [.annual, .monthly],
            localization: Self.localization,
            setting: .multiple
        )

        switch result {
        case .single:
            fail("Invalid result: \(result)")
        case let .multiple(packages):
            expect(packages).to(haveCount(2))

            let annual = packages[0]
            expect(annual.content) === Self.annual
            Self.verifyLocalizationWasProcessed(annual.localization, for: Self.annual)

            let monthly = packages[1]
            expect(monthly.content) === Self.monthly
            Self.verifyLocalizationWasProcessed(monthly.localization, for: Self.monthly)
        }
    }

    private static func verifyLocalizationWasProcessed(
        _ localization: ProcessedLocalizedConfiguration,
        for package: Package
    ) {
        expect(localization.title).to(
            contain(package.productName),
            description: "Localization wasn't processed"
        )
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class TemplateViewConfigurationFilteringTests: BaseTemplateViewConfigurationTests {

    func testFilterNoPackages() {
        expect(TemplateViewConfiguration.filter(packages: [], with: [.monthly])) == []
    }

    func testFilterPackagesWithEmptyList() {
        expect(TemplateViewConfiguration.filter(packages: [Self.monthly], with: [])) == []
    }

    func testFilterOutSinglePackge() {
        expect(TemplateViewConfiguration.filter(packages: [Self.monthly], with: [.annual])) == []
    }

    func testFilterOutNonSubscriptions() {
        expect(TemplateViewConfiguration.filter(packages: [Self.consumable], with: [.custom])) == []
    }

    func testFilterByPackageType() {
        expect(TemplateViewConfiguration.filter(packages: [Self.monthly, Self.annual], with: [.monthly])) == [
            Self.monthly
        ]
    }

    func testFilterWithDuplicatedPackageTypes() {
        expect(TemplateViewConfiguration.filter(packages: [Self.monthly, Self.annual], with: [.monthly, .monthly])) == [
            Self.monthly,
            Self.monthly
        ]
    }

    func testFilterReturningMultiplePackages() {
        expect(TemplateViewConfiguration.filter(packages: [Self.weekly, Self.monthly, Self.annual],
                                                with: [.weekly, .monthly])) == [
            Self.weekly,
            Self.monthly
        ]
    }

}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension BaseTemplateViewConfigurationTests {

    static let weekly = Package(
        identifier: "weekly",
        packageType: .weekly,
        storeProduct: TestData.productWithIntroOffer.toStoreProduct(),
        offeringIdentifier: offeringIdentifier
    )
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

    static let localization: PaywallData.LocalizedConfiguration = .init(
        title: "Title: {{ product_name }}",
        subtitle: "Get access to all our educational content trusted by thousands of parents.",
        callToAction: "Purchase for {{ price }}",
        callToActionWithIntroOffer: nil,
        offerDetails: "{{ price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month"
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
