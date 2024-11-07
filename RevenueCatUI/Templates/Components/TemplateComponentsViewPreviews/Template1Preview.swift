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

private enum Template1Preview {

    static let catUrl = URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!

    static let catImage = PaywallComponent.ImageComponent(
        source: .init(
            light: .init(
                original: catUrl,
                heic: catUrl,
                heicLowRes: catUrl
            )
        ),
        fitMode: .fit,
        gradientColors: ["#ffffff00", "#ffffff00", "#ffffffff"]
    )

    static let title = PaywallComponent.TextComponent(
        text: "title",
        fontFamily: nil,
        fontWeight: .black,
        color: .init(light: "#000000"),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        textStyle: .largeTitle,
        horizontalAlignment: .center
    )

    static let body = PaywallComponent.TextComponent(
        text: "body",
        fontFamily: nil,
        fontWeight: .regular,
        color: .init(light: "#000000"),
        backgroundColor: nil,
        padding: .zero,
        margin: .zero,
        textStyle: .body,
        horizontalAlignment: .center
    )

    static var packageStack: PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: "package_name",
                    fontWeight: .bold,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                )),
                .text(.init(
                    text: "package_detail",
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                ))
            ],
            dimension: .vertical(.center),
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
        stack: packageStack
    )

    static let purchaseButton = PaywallComponent.PurchaseButtonComponent(
        stack: .init(components: [
            // WIP: Intro offer state with "cta_intro",
            .text(.init(
                text: "cta",
                fontWeight: .bold,
                color: .init(light: "#ffffff"),
                backgroundColor: .init(light: "#e89d89"),
                padding: .init(top: 10,
                               bottom: 10,
                               leading: 30,
                               trailing: 30)
            ))
        ])
    )

    static let contentStack = PaywallComponent.StackComponent(
        components: [
            .text(title),
            .text(body),
            .package(package),
            .purchaseButton(purchaseButton)
        ],
        width: .init(type: .fill, value: nil),
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
        width: .init(type: .fill, value: nil),
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
            "package_name": .string("Monthly"),
            "package_detail": .string("Some price into"),
            "cta": .string("Get Started"),
            "cta_intro": .string("Claim Free Trial")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct Template1Preview_Previews: PreviewProvider {

    static var package: Package {
        return .init(identifier: "weekly",
                     packageType: .weekly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default")
    }

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Template 1
        TemplateComponentsView(
            paywallComponentsData: Template1Preview.data,
            offering: .init(identifier: "default",
                            serverDescription: "",
                            availablePackages: [package]),
            onDismiss: { }
        )
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Template 1")
    }
}

#endif

#endif
