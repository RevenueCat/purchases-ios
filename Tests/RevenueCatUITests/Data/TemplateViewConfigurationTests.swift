//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateViewConfigurationTests.swift
//
//  Created by Nacho Soto on 7/13/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

// swiftlint:disable file_length type_name type_body_length

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class BaseTemplateViewConfigurationTests: TestCase {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TemplateViewConfigurationCreationTests: BaseTemplateViewConfigurationTests {

    func testCreateWithNoPackages() {
        expect {
            try Config.create(
                with: [],
                activelySubscribedProductIdentifiers: [],
                filter: [PackageType.monthly.identifier],
                default: nil,
                localization: TestData.paywallWithIntroOffer.localizedConfiguration,
                localizationByTier: [:],
                tiers: [],
                setting: .single
            )
        }.to(throwError(TemplateError.noPackages))
    }

    func testCreateWithNoFilter() {
        expect {
            try Config.create(
                with: [TestData.monthlyPackage],
                activelySubscribedProductIdentifiers: [],
                filter: [],
                default: nil,
                localization: TestData.paywallWithIntroOffer.localizedConfiguration,
                localizationByTier: [:],
                tiers: [],
                setting: .single
            )
        }.to(throwError(TemplateError.emptyPackageList))
    }

    func testCreateWithNoLocalization() {
        expect {
            try Config.create(
                with: [TestData.monthlyPackage],
                activelySubscribedProductIdentifiers: [],
                filter: [PackageType.monthly.identifier],
                default: nil,
                localization: nil,
                localizationByTier: [:],
                tiers: [],
                setting: .single
            )
        }.to(throwError(TemplateError.noLocalization))
    }

    func testCreateSinglePackage() throws {
        let result = try Config.create(
            with: [TestData.monthlyPackage],
            activelySubscribedProductIdentifiers: [],
            filter: [PackageType.monthly.identifier],
            default: nil,
            localization: Self.localization,
            localizationByTier: [:],
            tiers: [],
            setting: .single
        )

        switch result {
        case let .single(package):
            expect(package.content) === TestData.monthlyPackage
            expect(package.currentlySubscribed) == false
            expect(package.discountRelativeToMostExpensivePerMonth).to(beNil())
            Self.verifyLocalizationWasProcessed(package.localization, for: TestData.monthlyPackage)
        case .multiple, .multiTier:
            fail("Invalid result: \(result)")
        }
    }

    func testCreateSingleSubscribedPackage() throws {
        let result = try Config.create(
            with: [TestData.monthlyPackage],
            activelySubscribedProductIdentifiers: [TestData.monthlyPackage.storeProduct.productIdentifier,
                                                  "Anotoher product"],
            filter: [PackageType.monthly.identifier],
            default: nil,
            localization: Self.localization,
            localizationByTier: [:],
            tiers: [],
            setting: .single
        )

        switch result {
        case let .single(package):
            expect(package.content) === TestData.monthlyPackage
            expect(package.currentlySubscribed) == true
            expect(package.discountRelativeToMostExpensivePerMonth).to(beNil())
            Self.verifyLocalizationWasProcessed(package.localization, for: TestData.monthlyPackage)
        case .multiple, .multiTier:
            fail("Invalid result: \(result)")
        }
    }

    func testCreateOnlyLifetime() throws {
        let result = try Config.create(
            with: [TestData.lifetimePackage],
            activelySubscribedProductIdentifiers: [],
            filter: [PackageType.lifetime.identifier],
            default: nil,
            localization: Self.localization,
            localizationByTier: [:],
            tiers: [],
            setting: .single
        )

        switch result {
        case let .single(package):
            expect(package.content) === TestData.lifetimePackage
            expect(package.currentlySubscribed) == false
            expect(package.discountRelativeToMostExpensivePerMonth).to(beNil())
            Self.verifyLocalizationWasProcessed(package.localization, for: TestData.lifetimePackage)
        case .multiple, .multiTier:
            fail("Invalid result: \(result)")
        }
    }

    func testCreateMultiplePackage() throws {
        let result = try Config.create(
            with: [TestData.monthlyPackage,
                   TestData.annualPackage,
                   TestData.weeklyPackage,
                   TestData.lifetimePackage,
                   Self.consumable],
            activelySubscribedProductIdentifiers: [
                TestData.monthlyPackage.storeProduct.productIdentifier,
                TestData.lifetimePackage.storeProduct.productIdentifier
            ],
            filter: [PackageType.annual.identifier,
                     PackageType.monthly.identifier,
                     PackageType.lifetime.identifier,
                     Self.consumable.identifier],
            default: PackageType.monthly.identifier,
            localization: Self.localization,
            localizationByTier: [:],
            tiers: [],
            setting: .multiple
        )

        switch result {
        case .single, .multiTier:
            fail("Invalid result: \(result)")
        case let .multiple(data):
            let (first, defaultPackage, packages) = (data.first, data.default, data.all)

            expect(first.content) === TestData.annualPackage
            expect(defaultPackage.content) === TestData.monthlyPackage

            expect(packages).to(haveCount(4))

            let annual = packages[0]
            expect(annual.content) === TestData.annualPackage
            expect(annual.currentlySubscribed) == false
            expect(annual.discountRelativeToMostExpensivePerMonth)
                .to(beCloseTo(0.36, within: 0.01))
            Self.verifyLocalizationWasProcessed(annual.localization, for: TestData.annualPackage)

            let monthly = packages[1]
            expect(monthly.content) === TestData.monthlyPackage
            expect(monthly.currentlySubscribed) == true
            expect(monthly.discountRelativeToMostExpensivePerMonth).to(beNil())
            Self.verifyLocalizationWasProcessed(monthly.localization, for: TestData.monthlyPackage)

            let lifetime = packages[2]
            expect(lifetime.content) === TestData.lifetimePackage
            expect(lifetime.currentlySubscribed) == true
            Self.verifyLocalizationWasProcessed(lifetime.localization, for: TestData.lifetimePackage)

            let consumable = packages[3]
            expect(consumable.content) === Self.consumable
            expect(consumable.currentlySubscribed) == false
            Self.verifyLocalizationWasProcessed(consumable.localization, for: Self.consumable)
        }
    }

    func testCreateMultitierWithNoTiers() {
        expect {
            try Config.create(
                with: [TestData.monthlyPackage],
                activelySubscribedProductIdentifiers: [],
                filter: [],
                default: nil,
                localization: nil,
                localizationByTier: [
                    "A": Self.localization
                ],
                tiers: [],
                setting: .multiTier
            )
        }.to(throwError(TemplateError.noTiers))
    }

    func testCreateMultitierWithNoAvailableProductsForAnyTier() {
        expect {
            let config = try Config.create(
                // We have some packages, but none of them are part of any tiers.
                with: [
                    TestData.weeklyPackage,
                    TestData.lifetimePackage
                ],
                activelySubscribedProductIdentifiers: [],
                filter: [PackageType.annual.identifier],
                default: nil,
                localization: nil,
                localizationByTier: [
                    "basic": Self.localization,
                    "standard": Self.localization
                ],
                // Our tiers contain 2 packages, but none of them are in the `with` array above.
                tiers: [
                    PaywallData.Tier(
                        id: "basic",
                        packages: [TestData.monthlyPackage.identifier],
                        defaultPackage: TestData.monthlyPackage.identifier
                    ),
                    PaywallData.Tier(
                        id: "standard",
                        packages: [TestData.sixMonthPackage.identifier],
                        defaultPackage: TestData.sixMonthPackage.identifier
                    )
                ],
                setting: .multiTier
            )
        }.to(throwError(TemplateError.noTiers))
    }

    func testCreateSingleTier() throws {
        let tier: PaywallData.Tier = .init(
            id: "standard",
            packages: [TestData.monthlyPackage.identifier],
            defaultPackage: TestData.monthlyPackage.identifier
        )

        let result = try Config.create(
            with: [TestData.monthlyPackage],
            activelySubscribedProductIdentifiers: [],
            filter: [],
            default: nil,
            localization: nil,
            localizationByTier: [
                tier.id: Self.localization2
            ],
            tiers: [
               tier
            ],
            setting: .multiTier
        )

        switch result {
        case .single, .multiple:
            fail("Invalid result: \(result)")

        case let .multiTier(firstTier, all, tierNames):
            expect(all).to(haveCount(1))
            expect(firstTier) == tier

            let tierData = try XCTUnwrap(all[firstTier])

            expect(tierData.default.content) === TestData.monthlyPackage
            expect(tierData.all.map(\.content)) == [TestData.monthlyPackage]
            expect(tierData.first.content) === TestData.monthlyPackage

            let package = tierData.first
            expect(package.currentlySubscribed) == false
            expect(package.discountRelativeToMostExpensivePerMonth).to(beNil())
            Self.verifyLocalizationWasProcessed(package.localization, for: TestData.monthlyPackage)

            expect(tierNames) == [
                tier: "Premium"
            ]
        }
    }

    func testCreateMultiTierWithMissingLocalization() throws {
        let tier: PaywallData.Tier = .init(
            id: "standard",
            packages: [TestData.monthlyPackage.identifier],
            defaultPackage: TestData.monthlyPackage.identifier
        )
        expect {
            try Config.create(
                with: [TestData.monthlyPackage],
                activelySubscribedProductIdentifiers: [],
                filter: [],
                default: nil,
                localization: nil,
                localizationByTier: [
                    "wrong ID": Self.localization2
                ],
                tiers: [
                    tier
                ],
                setting: .multiTier
            )
        }.to(throwError(TemplateError.missingLocalization(tier)))
    }

    // swiftlint:disable:next function_body_length
    func testCreateMultipleTiers() throws {
        let tiers: [PaywallData.Tier] = [
            .init(
                id: "standard",
                packages: [
                    TestData.monthlyPackage.identifier,
                    TestData.annualPackage.identifier
                ],
                defaultPackage: TestData.annualPackage.identifier
            ),
            .init(
                id: "premium",
                packages: [
                    TestData.weeklyPackage.identifier,
                    TestData.lifetimePackage.identifier
                ],
                defaultPackage: TestData.lifetimePackage.identifier
            )
        ]
        let result = try Config.create(
            with: [
                TestData.monthlyPackage,
                TestData.annualPackage,
                TestData.weeklyPackage,
                TestData.lifetimePackage
            ],
            activelySubscribedProductIdentifiers: [
                TestData.annualProduct.productIdentifier,
                TestData.lifetimeProduct.productIdentifier
            ],
            filter: [],
            default: nil,
            localization: nil,
            localizationByTier: [
                "standard": Self.localization,
                "premium": Self.localization2
            ],
            tiers: tiers,
            setting: .multiTier
        )

        switch result {
        case .single, .multiple:
            fail("Invalid result: \(result)")

        case let .multiTier(firstTier, all, tierNames):
            expect(all).to(haveCount(2))

            expect(firstTier) == tiers.first

            do {
                let firstTier = try XCTUnwrap(all[tiers[0]])

                let monthly = firstTier.all[0]
                expect(monthly.content) === TestData.monthlyPackage
                expect(monthly.currentlySubscribed) == false
                expect(monthly.discountRelativeToMostExpensivePerMonth).to(beNil())
                expect(monthly.localization.tierName).to(beNil())
                Self.verifyLocalizationWasProcessed(monthly.localization, for: TestData.monthlyPackage)

                let annual = firstTier.all[1]
                expect(annual.content) === TestData.annualPackage
                expect(annual.currentlySubscribed) == true
                expect(annual.discountRelativeToMostExpensivePerMonth)
                    .to(beCloseTo(0.36, within: 0.01))
                expect(annual.localization.tierName).to(beNil())
                Self.verifyLocalizationWasProcessed(annual.localization, for: TestData.annualPackage)
            }

            do {
                let secondTier = try XCTUnwrap(all[tiers[1]])

                let weekly = secondTier.all[0]
                expect(weekly.content) === TestData.weeklyPackage
                expect(weekly.currentlySubscribed) == false
                expect(weekly.discountRelativeToMostExpensivePerMonth).to(beNil())
                expect(weekly.localization.tierName) == "Premium"
                Self.verifyLocalizationWasProcessed(weekly.localization, for: TestData.weeklyPackage)

                let lifetime = secondTier.all[1]
                expect(lifetime.content) === TestData.lifetimePackage
                expect(lifetime.currentlySubscribed) == true
                expect(lifetime.discountRelativeToMostExpensivePerMonth).to(beNil())
                expect(lifetime.localization.tierName) == "Premium"
                Self.verifyLocalizationWasProcessed(lifetime.localization, for: TestData.lifetimePackage)
            }

            expect(tierNames) == [
                tiers[0]: "",
                tiers[1]: "Premium"
            ]
        }
    }

    func testCreateMultipleTiersWithDuplicateTierDoesNotCrash() throws {
        let tier = PaywallData.Tier(
            id: "standard",
            packages: [
                TestData.monthlyPackage.identifier,
                TestData.annualPackage.identifier
            ],
            defaultPackage: TestData.monthlyPackage.identifier
        )
        let result = try Config.create(
            with: [
                TestData.monthlyPackage,
                TestData.annualPackage
            ],
            activelySubscribedProductIdentifiers: [],
            filter: [],
            default: nil,
            localization: nil,
            localizationByTier: [
                "standard": Self.localization
            ],
            tiers: [tier, tier],
            setting: .multiTier
        )

        switch result {
        case .single, .multiple:
            fail("Invalid result: \(result)")

        case let .multiTier(firstTier, all, tierNames):
            expect(all).to(haveCount(1))
            expect(firstTier) == tier

            expect(all[firstTier]?.default.content) === TestData.monthlyPackage
            expect(all[firstTier]?.all.map(\.content)) == [TestData.monthlyPackage, TestData.annualPackage]
            expect(all[firstTier]?.first.content) == TestData.monthlyPackage

            let package = try XCTUnwrap(all[firstTier]?.first)
            expect(package.currentlySubscribed) == false
            expect(package.discountRelativeToMostExpensivePerMonth).to(beNil())
            Self.verifyLocalizationWasProcessed(package.localization, for: TestData.monthlyPackage)

            expect(tierNames) == [
                tier: ""
            ]
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

// MARK: -

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class TemplateViewConfigurationFilteringTests: BaseTemplateViewConfigurationTests {

    func testFilterNoPackages() {
        expect(TemplateViewConfiguration.filter(packages: [],
                                                with: [PackageType.monthly.identifier])) == []
    }

    func testFilterPackagesWithEmptyList() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage],
                                                with: [])) == []
    }

    func testFilterOutSinglePackge() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage],
                                                with: [PackageType.annual.identifier])) == []
    }

    func testConsumablesAreIncluded() {
        expect(TemplateViewConfiguration.filter(packages: [Self.consumable],
                                                with: [Self.consumable.identifier])) == [Self.consumable]
    }

    func testFilterByPackageType() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.monthlyPackage, TestData.annualPackage],
                                                with: [PackageType.monthly.identifier])) == [
            TestData.monthlyPackage
        ]
    }

    func testFilterWithDuplicatedPackageTypes() {
        expect(
            TemplateViewConfiguration.filter(
                packages: [TestData.monthlyPackage, TestData.annualPackage],
                with: [PackageType.monthly.identifier, PackageType.monthly.identifier]
            )
        ) == [
            TestData.monthlyPackage,
            TestData.monthlyPackage
        ]
    }

    func testFilterReturningMultiplePackages() {
        expect(TemplateViewConfiguration.filter(packages: [TestData.weeklyPackage,
                                                           TestData.monthlyPackage,
                                                           TestData.annualPackage],
                                                with: [PackageType.weekly.identifier,
                                                       PackageType.monthly.identifier])) == [
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
                with: [PackageType.monthly.identifier, PackageType.weekly.identifier])
        ) == [
            TestData.monthlyPackage,
            TestData.weeklyPackage
        ]
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TemplateViewConfigurationBaseExtensionTests: BaseTemplateViewConfigurationTests {

    fileprivate var singlePackageConfiguration: TemplateViewConfiguration.PackageConfiguration!
    fileprivate var multiPackageConfigurationSameText: TemplateViewConfiguration.PackageConfiguration!
    fileprivate var multiPackageConfigurationDifferentText: TemplateViewConfiguration.PackageConfiguration!
    fileprivate var multiPackageConfigurationNoOfferDetails: TemplateViewConfiguration.PackageConfiguration!
    fileprivate var multiTierConfigurationSameText: TemplateViewConfiguration.PackageConfiguration!
    fileprivate var multiTierConfigurationDifferentText: TemplateViewConfiguration.PackageConfiguration!
    fileprivate var multiTierConfigurationNoOfferDetails: TemplateViewConfiguration.PackageConfiguration!

    fileprivate static let tiers: [PaywallData.Tier] = [
        .init(
            id: "basic",
            packages: [
                package1.identifier,
                package2.identifier
            ],
            defaultPackage: package1.identifier
        ),
        .init(
            id: "premum",
            packages: [
                package3.identifier
            ],
            defaultPackage: package3.identifier
        )
    ]

    // swiftlint:disable:next function_body_length
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.singlePackageConfiguration = try Config.create(
            with: [Self.package1],
            activelySubscribedProductIdentifiers: [],
            filter: [Self.package1.packageType.identifier],
            default: nil,
            localization: Self.localization,
            localizationByTier: [:],
            tiers: [],
            setting: .single
        )
        self.multiPackageConfigurationSameText = try Config.create(
            with: Self.allPackages,
            activelySubscribedProductIdentifiers: [],
            filter: Self.allPackages.map(\.packageType.identifier),
            default: nil,
            localization: .init(
                title: "Title: {{ product_name }}",
                subtitle: "Get access to all our educational content trusted by thousands of parents.",
                callToAction: "Start now",
                callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} trial",
                offerDetails: "No trial",
                offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, " +
                "then {{ sub_price_per_month }} per month",
                features: []
            ),
            localizationByTier: [:],
            tiers: [],
            setting: .multiple
        )
        self.multiPackageConfigurationDifferentText = try Config.create(
            with: Self.allPackages,
            activelySubscribedProductIdentifiers: [],
            filter: Self.allPackages.map(\.packageType.identifier),
            default: nil,
            localization: Self.localization,
            localizationByTier: [:],
            tiers: [],
            setting: .multiple
        )
        self.multiPackageConfigurationNoOfferDetails = try Config.create(
            with: Self.allPackages,
            activelySubscribedProductIdentifiers: [],
            filter: Self.allPackages.map(\.packageType.identifier),
            default: nil,
            localization: .init(
                title: "Title: {{ product_name }}",
                subtitle: "Get access to all our educational content trusted by thousands of parents.",
                callToAction: "Start now",
                callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} trial",
                offerDetails: nil,
                features: []
            ),
            localizationByTier: [:],
            tiers: [],
            setting: .multiple
        )

        self.multiTierConfigurationSameText = try Config.create(
            with: Self.allPackages,
            activelySubscribedProductIdentifiers: [],
            filter: [],
            default: nil,
            localization: nil,
            localizationByTier: [
                Self.tiers[0].id: .init(
                    title: "Title: {{ product_name }}",
                    subtitle: "Get access to all our educational content trusted by thousands of parents.",
                    callToAction: "Start now",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} trial",
                    offerDetails: "No trial",
                    offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, " +
                    "then {{ sub_price_per_month }} per month",
                    features: []
                ),
                Self.tiers[1].id: .init(
                    title: "Title: {{ product_name }}",
                    subtitle: "Get access to all our educational content trusted by thousands of parents.",
                    callToAction: "Start now",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} trial",
                    offerDetails: "No trial",
                    offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, " +
                    "then {{ sub_price_per_month }} per month",
                    features: []
                )
            ],
            tiers: Self.tiers,
            setting: .multiTier
        )
        self.multiTierConfigurationDifferentText = try Config.create(
            with: Self.allPackages,
            activelySubscribedProductIdentifiers: [],
            filter: [],
            default: nil,
            localization: nil,
            localizationByTier: [
                Self.tiers[0].id: Self.localization,
                Self.tiers[1].id: Self.localization
            ],
            tiers: Self.tiers,
            setting: .multiTier
        )
        self.multiTierConfigurationNoOfferDetails = try Config.create(
            with: Self.allPackages,
            activelySubscribedProductIdentifiers: [],
            filter: [],
            default: nil,
            localization: nil,
            localizationByTier: [
                Self.tiers[0].id: .init(
                    title: "Title: {{ product_name }}",
                    subtitle: "Get access to all our educational content trusted by thousands of parents.",
                    callToAction: "Start now",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} trial",
                    offerDetails: nil,
                    features: []
                ),
                Self.tiers[1].id: .init(
                    title: "Title: {{ product_name }}",
                    subtitle: "Get access to all our educational content trusted by thousands of parents.",
                    callToAction: "Start now",
                    callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} trial",
                    offerDetails: nil,
                    features: []
                )
            ],
            tiers: Self.tiers,
            setting: .multiTier
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TemplateViewConfigurationPackagesProduceDifferentLabelsTests: TemplateViewConfigurationBaseExtensionTests {

    func testSinglePackageNoEligibility() throws {
        expect(self.singlePackageConfiguration.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: [:]
        )) == false
        expect(self.singlePackageConfiguration.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: [:]
        )) == false
    }

    func testSinglePackageEligible() throws {
        let eligibility: Eligibility = [TestData.monthlyPackage: .eligible]

        expect(self.singlePackageConfiguration.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == false
        expect(self.singlePackageConfiguration.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    func testSinglePackageNotEligible() throws {
        let eligibility: Eligibility = [TestData.monthlyPackage: .ineligible]

        expect(self.singlePackageConfiguration.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == false
        expect(self.singlePackageConfiguration.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    func testMultiPackageSameTextUnknownEligibility() throws {
        expect(self.multiPackageConfigurationSameText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.multiPackageConfigurationSameText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: [:]
        )) == true
    }

    func testMultiPackageSameTextNotEligible() throws {
        let eligibility: Eligibility = [
            Self.package1: .ineligible,
            Self.package2: .ineligible,
            Self.package3: .ineligible
        ]

        expect(self.multiPackageConfigurationSameText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == false
        expect(self.multiPackageConfigurationSameText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    func testMultiPackageSameTextWithSomeEligiblePackages() throws {
        let eligibility: Eligibility = [
            Self.package1: .eligible,
            Self.package2: .ineligible,
            Self.package3: .eligible
        ]

        expect(self.multiPackageConfigurationSameText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiPackageConfigurationSameText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    func testMultiPackageDifferentTextUnknownEligibility() throws {
        expect(self.multiPackageConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.multiPackageConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: [:]
        )) == true
    }

    func testMultiPackageDifferentTextNotEligible() throws {
        let eligibility: Eligibility = [
            Self.package1: .ineligible,
            Self.package2: .ineligible,
            Self.package3: .ineligible
        ]

        expect(self.multiPackageConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiPackageConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    func testMultiPackageDifferentTextWithSomeEligiblePackages() throws {
        let eligibility: Eligibility = [
            Self.package1: .eligible,
            Self.package2: .ineligible,
            Self.package3: .eligible
        ]

        expect(self.multiPackageConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiPackageConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    // MARK: - Multi-tier

    func testMultiTierSameTextUnknownEligibility() throws {
        expect(self.multiTierConfigurationSameText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.multiTierConfigurationSameText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: [:]
        )) == true
    }

    func testMultiTierSameTextNotEligible() throws {
        let eligibility: Eligibility = [
            Self.package1: .ineligible,
            Self.package2: .ineligible,
            Self.package3: .ineligible
        ]

        expect(self.multiTierConfigurationSameText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == false
        expect(self.multiTierConfigurationSameText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    func testMultiTierSameTextWithSomeEligiblePackages() throws {
        let eligibility: Eligibility = [
            Self.package1: .eligible,
            Self.package2: .ineligible,
            Self.package3: .eligible
        ]

        expect(self.multiTierConfigurationSameText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiTierConfigurationSameText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    func testMultiTierDifferentTextUnknownEligibility() throws {
        expect(self.multiTierConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.multiTierConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: [:]
        )) == true
    }

    func testMultiTierDifferentTextNotEligible() throws {
        let eligibility: Eligibility = [
            Self.package1: .ineligible,
            Self.package2: .ineligible,
            Self.package3: .ineligible
        ]

        expect(self.multiTierConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiTierConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    func testMultiTierDifferentTextWithSomeEligiblePackages() throws {
        let eligibility: Eligibility = [
            Self.package1: .eligible,
            Self.package2: .ineligible,
            Self.package3: .eligible
        ]

        expect(self.multiTierConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiTierConfigurationDifferentText.packagesProduceDifferentLabels(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TemplateViewConfigurationPackagesProduceAnyLabelTests: TemplateViewConfigurationBaseExtensionTests {

    func testSinglePackageNoEligibility() throws {
        expect(self.singlePackageConfiguration.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.singlePackageConfiguration.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: [:]
        )) == true
    }

    func testSinglePackageEligible() throws {
        let eligibility: Eligibility = [TestData.monthlyPackage: .eligible]

        expect(self.singlePackageConfiguration.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.singlePackageConfiguration.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    func testSinglePackageNotEligible() throws {
        let eligibility: Eligibility = [TestData.monthlyPackage: .ineligible]

        expect(self.singlePackageConfiguration.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.singlePackageConfiguration.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: eligibility
        )) == true
    }

    func testMultiPackageUnknownEligibility() throws {
        expect(self.multiPackageConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.multiPackageConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: [:]
        )) == false
    }

    func testMultiPackageNotEligible() throws {
        let eligibility: Eligibility = [
            Self.package1: .ineligible,
            Self.package2: .ineligible,
            Self.package3: .ineligible
        ]

        expect(self.multiPackageConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiPackageConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    func testMultiPackageWithSomeEligiblePackages() throws {
        let eligibility: Eligibility = [
            Self.package1: .eligible,
            Self.package2: .ineligible,
            Self.package3: .eligible
        ]

        expect(self.multiPackageConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiPackageConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    // MARK: - Multi-tier

    func testMultiTierUnknownEligibility() throws {
        expect(self.multiTierConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: [:]
        )) == true
        expect(self.multiTierConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: [:]
        )) == false
    }

    func testMultiTierNotEligible() throws {
        let eligibility: Eligibility = [
            Self.package1: .ineligible,
            Self.package2: .ineligible,
            Self.package3: .ineligible
        ]

        expect(self.multiTierConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiTierConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

    func testMultiTierWithSomeEligiblePackages() throws {
        let eligibility: Eligibility = [
            Self.package1: .eligible,
            Self.package2: .ineligible,
            Self.package3: .eligible
        ]

        expect(self.multiTierConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .callToAction,
            eligibility: eligibility
        )) == true
        expect(self.multiTierConfigurationNoOfferDetails.packagesProduceAnyLabel(
            for: .offerDetails,
            eligibility: eligibility
        )) == false
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BaseTemplateViewConfigurationTests {

    typealias Config = TemplateViewConfiguration.PackageConfiguration
    typealias Eligibility = TemplateViewConfiguration.PackageConfiguration.Eligibility

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
        offerDetails: "{{ sub_price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, " +
        "then {{ sub_price_per_month }} per month",
        features: []
    )
    static let localization2: PaywallData.LocalizedConfiguration = .init(
        title: "Title: {{ product_name }}",
        subtitle: "Get access to all our educational content trusted by thousands of parents.",
        callToAction: "Purchase for {{ price }}",
        callToActionWithIntroOffer: nil,
        offerDetails: "{{ sub_price_per_month }} per month",
        offerDetailsWithIntroOffer: "Start your {{ sub_offer_duration }} trial, " +
        "then {{ sub_price_per_month }} per month",
        features: [],
        tierName: "Premium"
    )

    static let package1 = TestData.monthlyPackage
    static let package2 = TestData.annualPackage
    static let package3 = TestData.weeklyPackage
    static let allPackages: [Package] = [
        package1,
        package2,
        package3
    ]

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
