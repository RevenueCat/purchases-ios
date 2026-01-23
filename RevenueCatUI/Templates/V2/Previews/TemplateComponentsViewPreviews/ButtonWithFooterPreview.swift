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

private enum ButtonWithSheetPreview {

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

    static let package = PaywallComponent.PackageComponent(
        packageID: "weekly",
        isSelectedByDefault: false,
        applePromoOfferProductCode: nil,
        stack: packageStack
    )

    static let bodyStack = PaywallComponent.StackComponent(
        components: [
            .text(body),
            .package(package)
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit),
        spacing: 30,
        backgroundColor: nil
    )

    static let purchaseButton = PaywallComponent.PurchaseButtonComponent(
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
        action: nil,
        method: nil
    )

    static let viewAllButton = PaywallComponent.ButtonComponent(
        action: .navigateTo(
            destination: .sheet(
                sheet: .init(id: "1234",
                             name: "sheet",
                             stack: .init(
                                components: [
                                    .stack(
                                        .init(
                                            components: [
                                                .button(.init(
                                                action: .navigateBack,
                                                stack: .init(
                                                    components: [
                                                        .stack(
                                                            .init(
                                                                components: [
                                                                    // WIP: Intro offer state with "cta_intro",
                                                                    .text(.init(
                                                                        text: "close",
                                                                        fontWeight: .bold,
                                                                        color: .init(light: .hex("#ffffff")),
                                                                        backgroundColor: nil,
                                                                        size: .init(width: .fit, height: .fit),
                                                                        padding: .init(top: 20,
                                                                                       bottom: 20,
                                                                                       leading: 20,
                                                                                       trailing: 20)
                                                                    ))
                                                                ],
                                                                dimension: .horizontal(.center, .start),
                                                                size: .init(width: .fit, height: .fit),
                                                                shape: .rectangle(nil)
                                                            )
                                                        )
                                                    ],
                                                    dimension: .horizontal(.center, .start),
                                                    size: .init(width: .fit, height: .fit),
                                                    shape: .rectangle(nil)
                                                )))
                                            ],
                                            dimension: .horizontal(.center, .start),
                                            size: .init(width: .fill, height: .fit),
                                            shape: .rectangle(nil)
                                        )
                                    ),

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
                                            size: .init(width: .fill, height: .fit),
                                            shape: .pill
                                        ),
                                        action: .inAppCheckout,
                                        method: .inAppCheckout
                                    )),
                                    .purchaseButton(.init(
                                        stack: .init(
                                            components: [
                                                // WIP: Intro offer state with "cta_intro",
                                                .text(.init(
                                                    text: "cta_web",
                                                    fontWeight: .bold,
                                                    color: .init(light: .hex("#ffffff")),
                                                    backgroundColor: .init(light: .hex("#e89d89")),
                                                    padding: .init(top: 10,
                                                                   bottom: 10,
                                                                   leading: 30,
                                                                   trailing: 30)
                                                ))
                                            ],
                                            size: .init(width: .fill, height: .fit),
                                            shape: .pill
                                        ),
                                        action: .webCheckout,
                                        method: .webCheckout(.init())
                                    )),
                                    .purchaseButton(.init(
                                        stack: .init(
                                            components: [
                                                // WIP: Intro offer state with "cta_intro",
                                                .text(.init(
                                                    text: "cta_web_selection",
                                                    fontWeight: .bold,
                                                    color: .init(light: .hex("#ffffff")),
                                                    backgroundColor: .init(light: .hex("#e89d89")),
                                                    padding: .init(top: 10,
                                                                   bottom: 10,
                                                                   leading: 30,
                                                                   trailing: 30)
                                                ))
                                            ],
                                            size: .init(width: .fill, height: .fit),
                                            shape: .pill
                                        ),
                                        action: .webProductSelection,
                                        method: .webProductSelection(.init())
                                    )),
                                    .purchaseButton(.init(
                                        stack: .init(
                                            components: [
                                                // WIP: Intro offer state with "cta_intro",
                                                .text(.init(
                                                    text: "cta_web_custom",
                                                    fontWeight: .bold,
                                                    color: .init(light: .hex("#ffffff")),
                                                    backgroundColor: .init(light: .hex("#e89d89")),
                                                    padding: .init(top: 10,
                                                                   bottom: 10,
                                                                   leading: 30,
                                                                   trailing: 30)
                                                ))
                                            ],
                                            size: .init(width: .fill, height: .fit),
                                            shape: .pill
                                        ),
                                        action: .webCheckout,
                                        method: .customWebCheckout(
                                            .init(customUrl: .init(url: "web_checkout_url", packageParam: "rc_package"))
                                        )
                                    )),
                                    .purchaseButton(.init(
                                        stack: .init(
                                            components: [
                                                // WIP: Intro offer state with "cta_intro",
                                                .text(.init(
                                                    text: "cta_web_selection_custom",
                                                    fontWeight: .bold,
                                                    color: .init(light: .hex("#ffffff")),
                                                    backgroundColor: .init(light: .hex("#e89d89")),
                                                    padding: .init(top: 10,
                                                                   bottom: 10,
                                                                   leading: 30,
                                                                   trailing: 30)
                                                ))
                                            ],
                                            size: .init(width: .fill, height: .fit),
                                            shape: .pill
                                        ),
                                        action: .webProductSelection,
                                        method: .customWebCheckout(
                                            .init(customUrl: .init(url: "web_checkout_url"))
                                        )
                                    ))
                                ],
                                size: .init(width: .fill, height: .fit),
                                background: .color(.init(light: .hex("#2b43bf"))),
                                padding: .init(top: 0, bottom: 30, leading: 20, trailing: 20),
                                shape: .rectangle(nil),
                                overflow: .default
                             ),
                             backgroundBlur: true,
                             size: .init(width: .fill, height: .fit)
                            )
            )),
        stack: .init(
            components: [
                // WIP: Intro offer state with "cta_intro",
                .text(.init(
                    text: "viewall",
                    fontWeight: .regular,
                    color: .init(light: .hex("#000000")),
                    backgroundColor: nil,
                    padding: .init(top: 10,
                                   bottom: 10,
                                   leading: 30,
                                   trailing: 30)
                ))
            ],
            shape: .pill
        )
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
        ],
        size: .init(width: .fill, height: .fit),
        overflow: .default
    )

    static let contentStack = PaywallComponent.StackComponent(
        components: [
            .text(title),
            .stack(bodyStack),
            .purchaseButton(purchaseButton),
            .button(viewAllButton)
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
        uiConfig: .init(
            app: .init(
                colors: [:],
                fonts: [:]
            ),
            localizations: [:],
            variableConfig: .init(
                variableCompatibilityMap: [:],
                functionCompatibilityMap: [:]
            )
        ),
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
            "package_name": .string("Monthly"),
            "package_detail": .string("Some price into"),
            "cta": .string("In-app Checkout"),
            "cta_web": .string("Web Checkout"),
            "cta_web_selection": .string("Web Selection"),
            "cta_web_custom": .string("Web Checkout (Custom)"),
            "cta_web_selection_custom": .string("Web Selection (Custom)"),
            "cta_intro": .string("Claim Free Trial"),
            "viewall": .string("View all plans"),

            "weekly_title": .string("Buy Weekly"),
            "weekly_desc": .string("Weekly something"),
            "monthly_title": .string("Buy Monthly"),
            "monthly_desc": .string("Monthly something"),

            "web_checkout_url": .string("https://rev.cat?rc_app_user_id=123"),

            "close": .string("X")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonWithSheetPreview_Previews: PreviewProvider {

    static let baseUrl = "https://pay.revenuecat.com/abcd1234/the-app-user-id"

    static var weeklyPackage: Package {
        return .init(identifier: "weekly",
                     packageType: .weekly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default",
                     webCheckoutUrl: URL(string: "\(baseUrl)?package_id=weekly")!)
    }

    static var monthlyPackage: Package {
        return .init(identifier: "monthly",
                     packageType: .monthly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default",
                     webCheckoutUrl: URL(string: "\(baseUrl)?package_id=monthly")!)
    }

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Template 1
        PaywallsV2View(
            paywallComponents: ButtonWithSheetPreview.paywallComponents,
            offering: .init(identifier: "default",
                            serverDescription: "",
                            availablePackages: [weeklyPackage, monthlyPackage],
                            webCheckoutUrl: URL(string: "https://pay.revenuecat.com/abcd1234/the-app-user-id")!),
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
