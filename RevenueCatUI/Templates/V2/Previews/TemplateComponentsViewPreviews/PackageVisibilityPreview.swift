//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageVisibilityPreview.swift
//
//  Created by RevenueCat on 3/26/26.

#if !os(tvOS) // For Paywalls V2

#if DEBUG

#if swift(>=5.9)

@_spi(Internal) import RevenueCat
import SwiftUI

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum PackageVisibilityPreview {

    static let monthlyPackage = PreviewMock.monthlyStandardPackage
    static let monthlyPackageWithIntro = Package(
        identifier: monthlyPackage.identifier,
        packageType: .monthly,
        storeProduct: TestStoreProduct(
            localizedTitle: "Monthly Standard",
            price: 4.99,
            currencyCode: "USD",
            localizedPriceString: "$4.99",
            productIdentifier: "com.revenuecat.preview.monthly_standard_intro",
            productType: .autoRenewableSubscription,
            localizedDescription: "Monthly Standard",
            subscriptionGroupIdentifier: "preview_group",
            subscriptionPeriod: .init(value: 1, unit: .month),
            introductoryDiscount: .init(
                identifier: "intro",
                price: 0,
                localizedPriceString: "$0.00",
                paymentMode: .freeTrial,
                subscriptionPeriod: .init(value: 7, unit: .day),
                numberOfPeriods: 1,
                type: .introductory
            ),
            locale: Locale(identifier: "en_US")
        ).toStoreProduct(),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )
    static let annualPackage = PreviewMock.annualStandardPackage
    static let weeklyPackage = PreviewMock.weeklyStandardPackage

    static let availablePackages: [Package] = [
        monthlyPackageWithIntro,
        annualPackage,
        weeklyPackage
    ]

    static let localizations: PaywallComponent.LocalizationDictionary = [
        "headline": .string("Choose your plan"),
        "monthly": .string("Monthly"),
        "annual": .string("Annual"),
        "weekly": .string("Weekly")
    ]

    static let title = PaywallComponent.TextComponent(
        text: "headline",
        fontWeight: .bold,
        color: .init(light: .hex("#111111"))
    )

    static func packageStack(title: String) -> PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: title,
                    fontWeight: .bold,
                    color: .init(light: .hex("#111111")),
                    overrides: [
                        .init(conditions: [.selected], properties: .init(
                            color: .init(light: .hex("#D83B01"))
                        ))
                    ]
                ))
            ],
            dimension: .vertical(.leading, .start),
            backgroundColor: .init(light: .hex("#F7F3ED")),
            padding: .init(top: 14, bottom: 14, leading: 16, trailing: 16),
            border: .init(color: .init(light: .hex("#C8C2B8")), width: 2),
            overrides: [
                .init(conditions: [.selected], properties: .init(
                    border: .init(color: .init(light: .hex("#D83B01")), width: 3)
                ))
            ]
        )
    }

    static func packageComponent(
        packageID: String,
        title: String,
        isSelectedByDefault: Bool,
        visible: Bool? = nil,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialPackageComponent>? = nil
    ) -> PaywallComponent.PackageComponent {
        return .init(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            visible: visible,
            applePromoOfferProductCode: nil,
            stack: packageStack(title: title),
            overrides: overrides
        )
    }

    static func paywallComponents(
        packages: [PaywallComponent.PackageComponent]
    ) -> Offering.PaywallComponents {
        let stack = PaywallComponent.StackComponent(
            components: [
                .text(title)
            ] + packages.map { .package($0) },
            dimension: .vertical(.leading, .start),
            spacing: 12,
            padding: .init(top: 24, bottom: 24, leading: 20, trailing: 20)
        )

        let data = PaywallComponentsData(
            templateName: "components",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(
                base: .init(
                    stack: stack,
                    stickyFooter: nil,
                    background: .color(.init(light: .hex("#FFF9F1")))
                )
            ),
            componentsLocalizations: ["en_US": localizations],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )

        return .init(
            uiConfig: PreviewUIConfig.make(),
            data: data
        )
    }

    static func paywallView(
        paywallComponents: Offering.PaywallComponents,
        eligibility: IntroEligibilityStatus
    ) -> some View {
        PaywallsV2View(
            paywallComponents: paywallComponents,
            offering: .init(
                identifier: "default",
                serverDescription: "",
                availablePackages: availablePackages,
                webCheckoutUrl: nil
            ),
            purchaseHandler: PurchaseHandler.default(),
            introEligibilityChecker: .default(),
            showZeroDecimalPlacePrices: true,
            onDismiss: { },
            failedToLoadFont: { _ in },
            colorScheme: .light,
            introEligibilityContext: .forPreview(packages: availablePackages, eligibility: eligibility)
        )
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageVisibilityPreview_Previews: PreviewProvider {

    static var previews: some View {
        PackageVisibilityPreview.paywallView(
            paywallComponents: PackageVisibilityPreview.paywallComponents(
                packages: [
                    .init(
                        packageID: PackageVisibilityPreview.monthlyPackage.identifier,
                        isSelectedByDefault: true,
                        visible: false,
                        applePromoOfferProductCode: nil,
                        stack: PackageVisibilityPreview.packageStack(title: "monthly")
                    ),
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.annualPackage.identifier,
                        title: "annual",
                        isSelectedByDefault: false
                    ),
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.weeklyPackage.identifier,
                        title: "weekly",
                        isSelectedByDefault: false
                    )
                ]
            ),
            eligibility: .ineligible
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Package: static hidden default → annual fallback selected")

        PackageVisibilityPreview.paywallView(
            paywallComponents: PackageVisibilityPreview.paywallComponents(
                packages: [
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.annualPackage.identifier,
                        title: "annual",
                        isSelectedByDefault: true
                    ),
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.monthlyPackageWithIntro.identifier,
                        title: "monthly",
                        isSelectedByDefault: false,
                        visible: false,
                        overrides: [
                            .init(conditions: [.introOffer], properties: .init(visible: true))
                        ]
                    ),
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.weeklyPackage.identifier,
                        title: "weekly",
                        isSelectedByDefault: false
                    )
                ]
            ),
            eligibility: .eligible
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Package: intro eligible → hidden monthly becomes visible")

        PackageVisibilityPreview.paywallView(
            paywallComponents: PackageVisibilityPreview.paywallComponents(
                packages: [
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.annualPackage.identifier,
                        title: "annual",
                        isSelectedByDefault: true
                    ),
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.monthlyPackageWithIntro.identifier,
                        title: "monthly",
                        isSelectedByDefault: false,
                        visible: false,
                        overrides: [
                            .init(conditions: [.introOffer], properties: .init(visible: true))
                        ]
                    ),
                    PackageVisibilityPreview.packageComponent(
                        packageID: PackageVisibilityPreview.weeklyPackage.identifier,
                        title: "weekly",
                        isSelectedByDefault: false
                    )
                ]
            ),
            eligibility: .ineligible
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Package: intro ineligible → hidden monthly stays hidden")

    }

}

#endif

#endif

#endif
