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

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

private enum PurchaseButtonInPackagePreview {

    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!

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
        size: .init(width: .fill, height: .fixed(270)),
        fitMode: .fill,
        maskShape: .convex
    )

    static let title = PaywallComponent.TextComponent(
        text: "title",
        fontName: nil,
        fontWeight: .black,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: 28,
        horizontalAlignment: .center
    )

    static let body = PaywallComponent.TextComponent(
        text: "body",
        fontName: nil,
        fontWeight: .regular,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: 15,
        horizontalAlignment: .center
    )
    static let orText = PaywallComponent.TextComponent(
        text: "or",
        fontName: nil,
        fontWeight: .regular,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: 15,
        horizontalAlignment: .center
    )

    static var packageStack: PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: "package_name",
                    fontWeight: .bold,
                    color: .init(light: .hex("#000000")),
                    padding: .zero,
                    margin: .zero
                )),
                .text(.init(
                    text: "package_detail",
                    color: .init(light: .hex("#000000")),
                    padding: .zero,
                    margin: .zero
                ))
            ],
            dimension: .vertical(.center, .start),
            spacing: 0,
            backgroundColor: nil,
            padding: .init(top: 0,
                           bottom: 0,
                           leading: 0,
                           trailing: 0)
        )
    }

    static var packageLifetimeStack: PaywallComponent.StackComponent {
        return .init(
            components: [
                .purchaseButton(.init(
                    stack: .init(
                        components: [
                            // WIP: Intro offer state with "cta_intro",
                            .text(.init(
                                text: "cta_lifetime",
                                fontWeight: .bold,
                                color: .init(light: .hex("#ffffff")),
                                backgroundColor: .init(light: .hex("#e89d89")),
                                padding: .init(top: 10,
                                               bottom: 10,
                                               leading: 30,
                                               trailing: 30)
                            ))
                        ],
                        shape: .pill
                    ),
                    action: .inAppCheckout,
                    method: .inAppCheckout
                ))
            ],
            dimension: .vertical(.center, .start),
            spacing: 0,
            backgroundColor: nil,
            padding: .init(top: 0,
                           bottom: 0,
                           leading: 0,
                           trailing: 0)
        )
    }

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

    static var packagesStack = PaywallComponent.StackComponent(
        components: [
            .package(makePackage(packageID: "weekly",
                                 nameTextLid: "weekly_title",
                                 detailTextLid: "weekly_desc",
                                 isSelectedByDefault: true)),
            .package(makePackage(packageID: "monthly",
                                 nameTextLid: "monthly_title",
                                 detailTextLid: "monthly_desc",
                                 isSelectedByDefault: true))
        ]
    )

    static let bodyStack = PaywallComponent.StackComponent(
        components: [
            .text(body),
            .stack(packagesStack),
            .purchaseButton(.init(
                stack: .init(
                    components: [
                        // WIP: Intro offer state with "cta_intro",
                        .text(.init(
                            text: "cta",
                            fontWeight: .bold,
                            color: .init(light: .hex("#ffffff")),
                            backgroundColor: .init(light: .hex("#e89d89")),
                            padding: .init(top: 10,
                                           bottom: 10,
                                           leading: 30,
                                           trailing: 30)
                        ))
                    ],
                    shape: .pill
                ),
                action: .inAppCheckout,
                method: .inAppCheckout
            )),
            .text(orText),
            .package(.init(
                packageID: "lifetime",
                isSelectedByDefault: false,
                applePromoOfferProductCode: nil,
                stack: packageLifetimeStack
            ))
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 30,
        backgroundColor: nil
    )

    static let contentStack = PaywallComponent.StackComponent(
        components: [
            .text(title),
            .stack(bodyStack)
        ],
        dimension: .vertical(.center, .spaceEvenly),
        size: .init(width: .fill, height: .fill),
        spacing: 30,
        backgroundColor: nil,
        margin: .init(top: 0,
                      bottom: 0,
                      leading: 20,
                      trailing: 20)
    )

    static let stack = PaywallComponent.StackComponent(
        components: [
            .image(catImage),
            .stack(contentStack)
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        spacing: 0
    )

    static let paywallComponents: Offering.PaywallComponents = .init(
        uiConfig: PreviewUIConfig.make(),
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
                    ],
                    overflow: .default
                ),
                stickyFooter: nil,
                background: .color(.init(
                    light: .hex("#ffffff")
                ))
            )
        ),
        componentsLocalizations: ["en_US": [
            "title": .string("Ignite your cat's curiosity"),
            "body": .string("Get access to all of our educational content trusted by thousands of pet parents."),
            "or": .string("or"),
            "cta": .string("Continue for {{ price_per_period }}"),
            "weekly_title": .string("Buy Weekly"),
            "weekly_desc": .string("Weekly something"),
            "monthly_title": .string("Buy Monthly"),
            "monthly_desc": .string("Monthly something"),
            "cta_lifetime": .string("Buy Lifetime")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonInPackagePreview_Previews: PreviewProvider {

    static var weeklyPackage: Package {
        return .init(identifier: "weekly",
                     packageType: .weekly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default",
                     webCheckoutUrl: nil)
    }

    static var monthlyPackage: Package {
        return .init(identifier: "monthly",
                     packageType: .monthly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default",
                     webCheckoutUrl: nil)
    }

    static var lifetimePackage: Package {
        return .init(identifier: "lifetime",
                     packageType: .lifetime,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default",
                     webCheckoutUrl: nil)
    }

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Template 1
        PaywallsV2View(
            paywallComponents: PurchaseButtonInPackagePreview.paywallComponents,
            offering: .init(identifier: "default",
                            serverDescription: "",
                            availablePackages: [weeklyPackage, monthlyPackage, lifetimePackage],
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
        .previewDisplayName("Template 1")
    }
}

#endif

#endif
