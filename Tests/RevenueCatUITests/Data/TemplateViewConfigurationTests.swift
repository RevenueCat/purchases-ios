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
                default: nil,
                localization: TestData.paywallWithIntroOffer.localizedConfiguration,
                setting: .single
            )
        }.to(throwError(TemplateError.noPackages))
    }

    func testCreateWithNoFilter() {
        expect {
            try Config.create(
                with: [TestData.monthlyPackage],
                filter: [],
                default: nil,
                localization: TestData.paywallWithIntroOffer.localizedConfiguration,
                setting: .single
            )
        }.to(throwError(TemplateError.emptyPackageList))
    }

    func testCreateSinglePackage() throws {
        let result = try Config.create(
            with: [TestData.monthlyPackage],
            filter: [.monthly],
            default: nil,
            localization: Self.localization,
            setting: .single
        )

        switch result {
        case let .single(package):
            expect(package.content) === TestData.monthlyPackage
            Self.verifyLocalizationWasProcessed(package.localization, for: TestData.monthlyPackage)
        case .multiple:
            fail("Invalid result: \(result)")
        }
    }

    func testCreateMultiplePackage() throws {
        let result = try Config.create(
            with: [TestData.monthlyPackage, TestData.annualPackage, TestData.weeklyPackage],
            filter: [.annual, .monthly],
            default: .monthly,
            localization: Self.localization,
            setting: .multiple
        )

        switch result {
        case .single:
            fail("Invalid result: \(result)")
        case let .multiple(first, defaultPackage, packages):
            expect(first.content) === TestData.annualPackage
            expect(defaultPackage.content) === TestData.monthlyPackage

            expect(packages).to(haveCount(2))

            let annual = packages[0]
            expect(annual.content) === TestData.annualPackage
            Self.verifyLocalizationWasProcessed(annual.localization, for: TestData.annualPackage)

            let monthly = packages[1]
            expect(monthly.content) === TestData.monthlyPackage
            Self.verifyLocalizationWasProcessed(monthly.localization, for: TestData.monthlyPackage)
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
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage], with: [])) == []
    }

    func testFilterOutSinglePackge() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage], with: [.annual])) == []
    }

    func testFilterOutNonSubscriptions() {
        expect(TemplateViewConfiguration.filter(packages: [Self.consumable], with: [.custom])) == []
    }

    func testFilterByPackageType() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage, TestData.annualPackage],
                                                with: [.monthly])) == [
            TestData.monthlyPackage
        ]
    }

    func testFilterWithDuplicatedPackageTypes() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage, TestData.annualPackage],
                                                with: [.monthly, .monthly])) == [
            TestData.monthlyPackage,
            TestData.monthlyPackage
        ]
    }

    func testFilterReturningMultiplePackages() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.weeklyPackage,
                                                           TestData.monthlyPackage,
                                                           TestData.annualPackage],
                                                with: [.weekly, .monthly])) == [
            TestData.weeklyPackage,
            TestData.monthlyPackage
        ]
    }

    func testFilterMaintainsOrder() {
        expect(
            TemplateViewConfiguration.filter(
                packages: [TestData.weeklyPackage,
                           TestData.monthlyPackage,
                           TestData.annualPackage],
                with: [.monthly, .weekly])
        ) == [
            TestData.monthlyPackage,
            TestData.weeklyPackage
        ]
    }

}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension BaseTemplateViewConfigurationTests {

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
        offerDetailsWithIntroOffer: "Start your {{ intro_duration }} trial, then {{ price_per_month }} per month",
        features: []
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
