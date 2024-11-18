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

#if PAYWALL_COMPONENTS

#if DEBUG

private enum Template5Preview {

    static let paywallState = PaywallState(selectedPackage: nil)

    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!

    static let catImage = PaywallComponent.ImageComponent(
        source: .init(
            light: .init(
                original: catUrl,
                heic: catUrl,
                heicLowRes: catUrl
            )
        ),
        fitMode: .fill,
        maxHeight: 200,
        gradientColors: ["#ffffff00", "#ffffff00", "#ffffffff"]
    )

    static let title = PaywallComponent.TextComponent(
        text: "title",
        fontName: nil,
        fontWeight: .black,
        color: .init(light: .hex("#000000")),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        fontSize: .headingL,
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
        fontSize: .bodyM,
        horizontalAlignment: .leading
    )

    static let packages: [PaywallComponent.PackageComponent] = [
            makePackage(packageID: "weekly",
                        nameTextLid: "weekly_name",
                        detailTextLid: "weekly_detail"),
            makePackage(packageID: "non_existant_package",
                        nameTextLid: "non_existant_name",
                        detailTextLid: "non_existant_detail"),
            makePackage(packageID: "monthly",
                        nameTextLid: "monthly_name",
                        detailTextLid: "monthly_detail",
                        isSelectedByDefault: true)
        ]

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
                    padding: .zero,
                    margin: .zero
                )),
                .text(.init(
                    text: detailTextLid,
                    color: .init(light: .hex("#000000")),
                    padding: .zero,
                    margin: .zero
                ))
            ],
            dimension: .vertical(.leading, .start),
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
            border: .init(color: .init(light: .hex("#cccccc")), width: 1)
        )

        return PaywallComponent.PackageComponent(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            stack: stack
        )
    }

    static let packagesStack = PaywallComponent.StackComponent(
        components: [
            .package(makePackage(packageID: "weekly",
                                 nameTextLid: "weekly_name",
                                 detailTextLid: "weekly_detail")),
            .package(makePackage(packageID: "non_existant_package",
                                 nameTextLid: "non_existant_name",
                                 detailTextLid: "non_existant_detail")),
            .package(makePackage(packageID: "monthly",
                                 nameTextLid: "monthly_name",
                                 detailTextLid: "monthly_detail",
                                 isSelectedByDefault: true)),
            .text(.init(
                text: "package_terms",
                color: .init(light: .hex("#999999")),
                fontSize: .bodyS
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
        )
    )

    static let purchaseButtonStack = PaywallComponent.StackComponent(
        components: [
            .purchaseButton(purchaseButton)
        ],
        dimension: .horizontal(.center, .start),
        spacing: 0,
        backgroundColor: nil
    )

    static let contentStack = PaywallComponent.StackComponent(
        components: [
            .text(title),
            .text(body),
            .stack(packagesStack),
            .stack(purchaseButtonStack)
        ],
        dimension: .vertical(.leading, .start),
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
        spacing: 20,
        backgroundColor: nil
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
                stickyFooter: nil
            )
        ),
        componentsLocalizations: ["en_US": [
            "title": .string("Ignite your cat's curiosity"),
            "body": .string("Get access to all of our educational content trusted by thousands of pet parents."),
            "cta": .string("Get Started"),
            "cta_intro": .string("Claim Free Trial"),

            // Packages
            "weekly_name": .string("Weekly"),
            "weekly_detail": .string("Get for $39.99/week"),
            "monthly_name": .string("Monthly"),
            "monthly_detail": .string("Get for $139.99/month"),
            "non_existant_name": .string("THIS SHOULDN'T SHOW"),
            "non_existant_detail": .string("THIS SHOULDN'T SHOW"),

            "package_terms": .string("Recurring billing. Cancel anytime.")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct Template5Preview_Previews: PreviewProvider {

    static var package: Package {
        return .init(identifier: "weekly",
                     packageType: .weekly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default")
    }

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Template 5
        TemplateComponentsView(
            paywallComponentsData: Template5Preview.data,
            offering: Offering(identifier: "default",
                               serverDescription: "",
                               availablePackages: [
                                Package(identifier: "weekly",
                                        packageType: .weekly,
                                        storeProduct: .init(sk1Product: .init()),
                                        offeringIdentifier: "default"),
                                Package(identifier: "monthly",
                                        packageType: .monthly,
                                        storeProduct: .init(sk1Product: .init()),
                                        offeringIdentifier: "default")
                               ]),
            onDismiss: { }
        )
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Template 5")
    }
}

#endif

#endif
