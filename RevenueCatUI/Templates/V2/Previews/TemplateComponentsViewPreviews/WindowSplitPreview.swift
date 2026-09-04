//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WindowSplitPreview.swift
//
//  Created by Josh Holtz on 9/2/26.
//
// PoC: "pick your split" adaptive layout for foldables and tablets.
// Mirrors the editor's split transform output: content and purchase panes
// wrapped in a stack that is vertical by default and flips horizontal via a
// window size rule (width >= 700 AND height >= 480).

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

private enum WindowSplitPreview {

    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!

    static let heroImage = PaywallComponent.ImageComponent(
        source: .init(
            light: .init(
                width: 750,
                height: 530,
                original: catUrl,
                heic: catUrl,
                heicLowRes: catUrl
            )
        ),
        size: .init(width: .fill, height: .fixed(260)),
        fitMode: .fill
    )

    static let title = PaywallComponent.TextComponent(
        text: "title",
        fontWeight: .black,
        color: .init(light: .hex("#000000")),
        padding: .init(top: 20, bottom: 0, leading: 20, trailing: 20),
        margin: .zero,
        fontSize: 28,
        horizontalAlignment: .center
    )

    static let body = PaywallComponent.TextComponent(
        text: "body",
        color: .init(light: .hex("#000000")),
        padding: .init(top: 8, bottom: 0, leading: 20, trailing: 20),
        margin: .zero,
        fontSize: 15,
        horizontalAlignment: .center
    )

    static let package = PaywallComponent.PackageComponent(
        packageID: "monthly",
        isSelectedByDefault: true,
        applePromoOfferProductCode: nil,
        stack: .init(
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
            size: .init(width: .fill, height: .fit(nil)),
            spacing: 0,
            backgroundColor: nil,
            padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12),
            shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12)),
            border: .init(color: .init(light: .hex("#cccccc")), width: 1)
        )
    )

    static let purchaseButton = PaywallComponent.PurchaseButtonComponent(
        stack: .init(
            components: [
                .text(.init(
                    text: "cta",
                    fontWeight: .bold,
                    color: .init(light: .hex("#ffffff")),
                    backgroundColor: .init(light: .hex("#e89d89")),
                    size: .init(width: .fill, height: .fit(nil)),
                    padding: .init(top: 12, bottom: 12, leading: 30, trailing: 30)
                ))
            ],
            size: .init(width: .fill, height: .fit(nil)),
            shape: .pill
        ),
        action: nil,
        method: nil,
        name: nil
    )

    static let legal = PaywallComponent.TextComponent(
        text: "legal",
        color: .init(light: .hex("#999999")),
        padding: .zero,
        margin: .zero,
        fontSize: 12,
        horizontalAlignment: .center
    )

    /// Leading pane: marketing content.
    static let contentPane = PaywallComponent.StackComponent(
        components: [
            .image(heroImage),
            .text(title),
            .text(body)
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit(nil)),
        spacing: 0,
        backgroundColor: nil
    )

    /// Trailing pane: packages + CTA + legal.
    static let purchasePane = PaywallComponent.StackComponent(
        components: [
            .package(package),
            .purchaseButton(purchaseButton),
            .text(legal)
        ],
        dimension: .vertical(.center, .center),
        size: .init(width: .fill, height: .fit(nil)),
        spacing: 16,
        backgroundColor: nil,
        padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16)
    )

    /// The split wrapper: vertical by default, horizontal when the window is
    /// at least 700pt wide AND 480pt tall (so landscape phones stay vertical).
    static let splitWrapper = PaywallComponent.StackComponent(
        components: [
            .stack(contentPane),
            .stack(purchasePane)
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fit(nil)),
        spacing: 0,
        backgroundColor: nil,
        overrides: [
            .init(
                extendedConditions: [
                    .windowWidth(operator: .greaterThanOrEqual, value: 700),
                    .windowHeight(operator: .greaterThanOrEqual, value: 480)
                ],
                properties: .init(
                    dimension: .horizontal(.top, .start)
                )
            )
        ]
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
                        .stack(splitWrapper)
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
            "title": .string("Experience Pro today!"),
            "body": .string("Check out the power of all we offer."),
            "package_name": .string("Monthly"),
            "package_detail": .string("$9.99/mo"),
            "cta": .string("Continue"),
            "legal": .string("Cancel anytime. Restore purchases.")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WindowSplitPreview_Previews: PreviewProvider {

    static let baseUrl = "https://pay.revenuecat.com/abcd1234/the-app-user-id"

    static var monthlyPackage: Package {
        return .init(identifier: "monthly",
                     packageType: .monthly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default",
                     webCheckoutUrl: URL(string: "\(baseUrl)?package_id=monthly")!)
    }

    static var offering: Offering {
        .init(identifier: "default",
              serverDescription: "",
              availablePackages: [monthlyPackage],
              webCheckoutUrl: URL(string: baseUrl)!)
    }

    static func paywall() -> some View {
        PaywallsV2View(
            paywallComponents: WindowSplitPreview.paywallComponents,
            offering: offering,
            purchaseHandler: PurchaseHandler.default(),
            introEligibilityChecker: .default(),
            showZeroDecimalPlacePrices: true,
            onDismiss: { },
            failedToLoadFont: { _ in },
            colorScheme: .light
        )
        .previewRequiredPaywallsV2Properties()
    }

    static var previews: some View {

        paywall()
            .previewLayout(.fixed(width: 402, height: 874))
            .previewDisplayName("Phone portrait (vertical)")

        paywall()
            .previewLayout(.fixed(width: 874, height: 402))
            .previewDisplayName("Phone landscape (vertical: height floor)")

        paywall()
            .previewLayout(.fixed(width: 904, height: 640))
            .previewDisplayName("iPhone Fold unfolded (split)")

        paywall()
            .previewLayout(.fixed(width: 1024, height: 768))
            .previewDisplayName("iPad (split)")
    }

}

#endif

#endif
