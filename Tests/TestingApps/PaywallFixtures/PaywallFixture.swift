//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFixture.swift
//
//  Created by Facundo Menzella on 8/5/26.

import Foundation
@_spi(Internal) import RevenueCat

/// A paywall defined in code rather than fetched, so a test can assert against a known component
/// tree. Add a case here and the app can render it by name.
///
/// Everything here is built from `@_spi(Internal)` API only, deliberately: reaching RevenueCatUI's
/// internal preview helpers would need `@testable`, which does not work from every app target.
enum PaywallFixture: String, CaseIterable {

    /// A button whose only content is an icon, so it has no text for a screen reader to announce.
    case iconOnlyButton = "icon_only_button"

    var title: String {
        switch self {
        case .iconOnlyButton:
            return "Icon-only button"
        }
    }

    var componentsData: PaywallComponentsData {
        switch self {
        case .iconOnlyButton:
            return Self.iconOnlyButtonComponentsData()
        }
    }

    /// Mirrors how the SDK receives a paywall: components plus a `UIConfig`, on an offering that
    /// carries packages. A paywall whose offering has no packages renders the default paywall
    /// instead of the components.
    var offering: Offering {
        return Offering(
            identifier: self.rawValue,
            serverDescription: self.title,
            metadata: [:],
            paywallComponents: .init(uiConfig: Self.uiConfig, data: self.componentsData),
            availablePackages: [Self.monthlyPackage(offeringIdentifier: self.rawValue)],
            webCheckoutUrl: nil
        )
    }

}

private extension PaywallFixture {

    /// Period words the SDK expects to find when resolving variables. An empty `localizations` map
    /// is not equivalent: components that reference them render nothing.
    static let uiConfig = UIConfig(
        app: .init(colors: [:], fonts: [:]),
        localizations: [
            "en_US": [
                "day": "day", "daily": "daily", "day_short": "day",
                "week": "week", "weekly": "weekly", "week_short": "wk",
                "month": "month", "monthly": "monthly", "month_short": "mo",
                "year": "year", "yearly": "yearly", "year_short": "yr",
                "annual": "annual", "annually": "annually", "annual_short": "yr",
                "free": "free", "percent": "%d%%"
            ]
        ],
        variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
    )

    static func monthlyPackage(offeringIdentifier: String) -> Package {
        let product = TestStoreProduct(
            localizedTitle: "Monthly",
            price: 4.99,
            localizedPriceString: "$4.99",
            productIdentifier: "com.revenuecat.fixtures.monthly",
            productType: .autoRenewableSubscription,
            localizedDescription: "Monthly subscription",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .month)
        )

        return Package(
            identifier: "$rc_monthly",
            packageType: .monthly,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: offeringIdentifier,
            webCheckoutUrl: nil
        )
    }

    static func iconOnlyButtonComponentsData() -> PaywallComponentsData {
        return .init(
            templateName: "fixture-icon-only-button",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [
                        .button(.init(
                            action: .navigateBack,
                            stack: .init(
                                components: [
                                    .icon(.init(
                                        baseUrl: "https://icons.pawwalls.com/icons",
                                        iconName: "x",
                                        formats: .init(
                                            svg: "x.svg",
                                            png: "x.png",
                                            heic: "x.heic",
                                            webp: "x.webp"
                                        ),
                                        size: .init(width: .fixed(24), height: .fixed(24)),
                                        padding: .zero,
                                        margin: .zero,
                                        color: .init(light: .hex("#000000")),
                                        iconBackground: nil
                                    ))
                                ],
                                size: .init(width: .fit(nil), height: .fit(nil)),
                                padding: .init(top: 8, bottom: 8, leading: 8, trailing: 8)
                            )
                        )),
                        .text(.init(
                            text: "body_lid",
                            color: .init(light: .hex("#000000"))
                        ))
                    ],
                    dimension: .vertical(.center, .start),
                    size: .init(width: .fill, height: .fill),
                    spacing: 16,
                    backgroundColor: .init(light: .hex("#ffffff")),
                    padding: .init(top: 80, bottom: 24, leading: 16, trailing: 16)
                ),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: [
                "en_US": [
                    "body_lid": .string("Everything you need, in one place.")
                ]
            ],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

}
