//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestPaywallPreviews.swift
//
//  Created by Josh Holtz on 9/26/24.
// swiftlint:disable file_length

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

// swiftlint:disable force_unwrapping

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_body_length
private enum FamilySharingTogglePreview {

    @MainActor
    static let paywallState = PackageContext(
        package: nil,
        variableContext: .init()
    )

    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!
    static let catFamilyUrl = URL(string: "https://assets.pawwalls.com/1151049_1736611979.heic")!

    static let catImage = PaywallComponent.ImageComponent(
        source: .init(
            light: .init(
                width: 750,
                height: 530,
                original: catUrl,
                heic: catUrl,
                heicLowRes: catUrl
            )
        ),
        fitMode: .fill,
        colorOverlay: .init(light: .linear(0, [
            .init(color: "#ffffff", percent: 0),
            .init(color: "#ffffff00", percent: 40)
        ]))
    )

    static let catFamilyImage = PaywallComponent.ImageComponent(
        source: .init(
            light: .init(
                width: 750,
                height: 530,
                original: catFamilyUrl,
                heic: catFamilyUrl,
                heicLowRes: catFamilyUrl
            )
        ),
        fitMode: .fill,
        colorOverlay: .init(light: .linear(0, [
            .init(color: "#ffffff", percent: 0),
            .init(color: "#ffffff00", percent: 40)
        ]))
    )

    static let title = PaywallComponent.TextComponent(
        text: "title",
        fontName: nil,
        fontWeight: .black,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: 22,
        horizontalAlignment: .leading
    )

    static let titleFamily = PaywallComponent.TextComponent(
        text: "title_family",
        fontName: nil,
        fontWeight: .black,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: 22,
        horizontalAlignment: .leading
    )

    static let body = PaywallComponent.TextComponent(
        text: "body",
        fontName: nil,
        fontWeight: .regular,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: 14,
        horizontalAlignment: .leading
    )

    static func makePackage(
        packageID: String,
        nameTextLid: String,
        detailTextLid: String,
        isSelectedByDefault: Bool = false
    ) -> PaywallComponent.PackageComponent {
        let stack: PaywallComponent.StackComponent = .init(
            components: [
                .text(.init(
                    text: nameTextLid,
                    fontWeight: .bold,
                    color: .init(light: .hex("#000000")),
                    size: .init(width: .fill, height: .fit),
                    padding: .zero,
                    margin: .zero,
                    horizontalAlignment: .leading
                )),
                .text(.init(
                    text: detailTextLid,
                    color: .init(light: .hex("#000000")),
                    size: .init(width: .fill, height: .fit),
                    padding: .zero,
                    margin: .zero,
                    horizontalAlignment: .leading
                ))
            ],
            dimension: .vertical(.leading, .start),
            size: .init(width: .fill, height: .fit),
            spacing: 0,
            backgroundColor: nil,
            padding: PaywallComponent.Padding(top: 10,
                                              bottom: 10,
                                              leading: 20,
                                              trailing: 20),
            shape: .rectangle(.init(topLeading: 16,
                                    topTrailing: 16,
                                    bottomLeading: 16,
                                    bottomTrailing: 20)),
            border: .init(color: .init(light: .hex("#cccccc")), width: 1),
            overrides: [
                .init(conditions: [
                    .selected
                ], properties: .init(
                    backgroundColor: .init(light: .hex("#ffdfdd")),
                    border: .init(color: .init(light: .hex("#e89d89")), width: 1)
                ))
            ]
        )

        return PaywallComponent.PackageComponent(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            applePromoOfferProductCode: nil,
            stack: stack
        )
    }

    static func makePackagesStack(prefix: String,
                                  weeklyPackageIdentifier: String,
                                  isWeeklySelectedByDefault: Bool,
                                  monthlyPackageIdentifier: String,
                                  isMonthlySelectedByDefault: Bool) -> PaywallComponent.StackComponent {
        return .init(
            components: [
                .package(makePackage(packageID: weeklyPackageIdentifier,
                                     nameTextLid: "\(prefix)_weekly_name",
                                     detailTextLid: "\(prefix)_weekly_detail",
                                     isSelectedByDefault: isWeeklySelectedByDefault)),
                .package(makePackage(packageID: "non_existant_package",
                                     nameTextLid: "\(prefix)_non_existant_name",
                                     detailTextLid: "\(prefix)_non_existant_detail")),
                .package(makePackage(packageID: monthlyPackageIdentifier,
                                     nameTextLid: "\(prefix)_monthly_name",
                                     detailTextLid: "\(prefix)_monthly_detail",
                                     isSelectedByDefault: isMonthlySelectedByDefault)),
                .text(.init(
                    text: "package_terms",
                    color: .init(light: .hex("#999999")),
                    fontSize: 13
                ))
            ],
            dimension: .vertical(.center, .start),
            spacing: 10,
            backgroundColor: nil,
            margin: .init(top: 20,
                          bottom: 0,
                          leading: 0,
                          trailing: 0)
        )
    }

    static let tabs = PaywallComponent.tabs(
        .init(
            control: .init(
                type: .toggle,
                stack: .init(
                    components: [
                        .text(.init(
                            text: "toggle_text",
                            color: .init(light: .hex("#000000")),
                            size: .init(width: .fit, height: .fit),
                            overrides: [
                                .init(conditions: [
                                    .selected
                                ], properties: .init(
                                    color: .init(light: .hex("#ffffff"))
                                ))
                            ]
                        )),
                        .tabControlToggle(.init(
                            defaultValue: false,
                            thumbColorOn: .init(light: .hex("#e89d89")),
                            thumbColorOff: .init(light: .hex("#ffffff")),
                            trackColorOn: .init(light: .hex("#f2c7bd")),
                            trackColorOff: .init(light: .hex("#dedede"))
                        ))
                    ],
                    dimension: .horizontal(.center, .start),
                    size: .init(width: .fit, height: .fit)
                )
            ),
            tabs: [
                // Tab 1
                .init(id: "1", stack: .init(
                    components: [
                        .image(catImage),
                        .stack(.init(
                            components: [
                                .text(title),
                                .text(body),

                                .tabControl(.init()),
                                .stack(makePackagesStack(
                                    prefix: "standard",
                                    weeklyPackageIdentifier: PreviewMock.weeklyStandardPackage.packageIdentifier,
                                    isWeeklySelectedByDefault: false,
                                    monthlyPackageIdentifier: PreviewMock.monthlyStandardPackage.packageIdentifier,
                                    isMonthlySelectedByDefault: true
                                )),

                                .stack(purchaseButtonStack)
                            ],
                            spacing: 20,
                            margin: .init(top: 0, bottom: 0, leading: 20, trailing: 20)
                        ))
                    ],
                    spacing: 0
                )),
                // Tab 2
                .init(id: "2", stack: .init(
                    components: [
                        .image(catFamilyImage),
                        .stack(.init(
                            components: [
                                .text(titleFamily),
                                 .text(body),

                                 .tabControl(.init()),
                                 .stack(makePackagesStack(
                                     prefix: "family",
                                     weeklyPackageIdentifier: PreviewMock.weeklyPremiumPackage.packageIdentifier,
                                     isWeeklySelectedByDefault: true,
                                     monthlyPackageIdentifier: PreviewMock.monthlyPremiumPackage.packageIdentifier,
                                     isMonthlySelectedByDefault: false
                                 )),

                                 .stack(purchaseButtonStack)
                            ],
                            spacing: 20,
                            margin: .init(top: 0, bottom: 0, leading: 20, trailing: 20)
                        ))
                    ],
                    spacing: 0
                ))
            ]
        )
    )

    static let purchaseButton = PaywallComponent.PurchaseButtonComponent(
        stack: .init(
            components: [
                // WIP: Intro offer state with "cta_intro",
                .text(.init(
                    text: "cta",
                    fontWeight: .bold,
                    color: .init(light: .hex("#ffffff"))
                ))
            ],
            backgroundColor: .init(light: .hex("#e89d89")),
            padding: .init(top: 15,
                           bottom: 15,
                           leading: 50,
                           trailing: 50),
            shape: .rectangle(.init(topLeading: 16,
                                    topTrailing: 16,
                                    bottomLeading: 16,
                                    bottomTrailing: 16))
        ),
        action: .inAppCheckout,
        method: .inAppCheckout
    )

    static let purchaseButtonStack = PaywallComponent.StackComponent(
        components: [
            .purchaseButton(purchaseButton)
        ],
        dimension: .horizontal(.center, .start),
        spacing: 0,
        backgroundColor: nil
    )

    static let stack = PaywallComponent.StackComponent(
        components: [
            tabs
        ],
        spacing: 20,
        backgroundColor: nil
    )

    static let paywallComponents: Offering.PaywallComponents = .init(
        uiConfig: PreviewMock.uiConfig,
        data: data
    )

    static let data: PaywallComponentsData = .init(
        templateName: "components",
        assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
        componentsConfig: .init(
            base: .init(
                stack: .init(
                    components: [
                        .stack(stack)
                    ]
                ),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )
        ),
        componentsLocalizations: ["en_US": [
            "title": .string("Ignite your cat's curiosity"),
            "title_family": .string("Ignite your cats' curiosity"),
            "body": .string("Get access to all of our educational content trusted by thousands of pet parents."),
            "cta": .string("Continue for {{ price_per_period }}"),
            "cta_intro": .string("Claim Free Trial"),

            // Standard Packages
            "standard_weekly_name": .string("Standard {{ sub_period }}"),
            "standard_weekly_detail": .string("Get for {{ total_price_and_per_month }}"),
            "standard_monthly_name": .string("Standard {{ sub_period }} "),
            "standard_monthly_detail": .string("Get for {{ total_price_and_per_month }}"),
            "standard_non_existant_name": .string("THIS SHOULDN'T SHOW"),
            "standard_non_existant_detail": .string("THIS SHOULDN'T SHOW"),

            // Family Packages
            "family_weekly_name": .string("Family {{ sub_period }}"),
            "family_weekly_detail": .string("Get for {{ total_price_and_per_month }}"),
            "family_monthly_name": .string("Family {{ sub_period }}"),
            "family_monthly_detail": .string("Get for {{ total_price_and_per_month }}"),
            "family_non_existant_name": .string("THIS SHOULDN'T SHOW"),
            "family_non_existant_detail": .string("THIS SHOULDN'T SHOW"),

            "package_terms": .string("Recurring billing. Cancel anytime."),

            "toggle_text": .string("Family Sharing?")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FamilySharingTogglePreview_Previews: PreviewProvider {

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Family Sharing Toggle
        PaywallsV2View(
            paywallComponents: FamilySharingTogglePreview.paywallComponents,
            offering: Offering(identifier: "default",
                               serverDescription: "",
                               availablePackages: [
                                PreviewMock.weeklyStandardPackage,
                                PreviewMock.monthlyStandardPackage,
                                PreviewMock.weeklyPremiumPackage,
                                PreviewMock.monthlyPremiumPackage
                               ],
                               webCheckoutUrl: nil),
            purchaseHandler: PurchaseHandler.default(),
            introEligibilityChecker: .default(),
            showZeroDecimalPlacePrices: true,
            onDismiss: { },
            fallbackContent: .customView(AnyView(Text("Fallback paywall"))),
            failedToLoadFont: { _ in },
            colorScheme: .light
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Family Sharing Toggle")
    }
}

#endif

#endif
