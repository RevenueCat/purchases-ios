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

    /// Packages outside and inside tabs, authored default hidden. Cards rename themselves when
    /// selected, so a UI test can read the selection.
    case mixedTabsPageDefault = "mixed_tabs_page_default"

    /// Every base currency and price variable, one per line, on a product whose displayed price
    /// spells the currency with its ISO code the way the Ukraine storefront does.
    case priceVariables = "price_variables"

    /// The offer-price variables, on the same product with a paid introductory offer.
    case offerPriceVariables = "offer_price_variables"

    var title: String {
        switch self {
        case .iconOnlyButton:
            return "Icon-only button"
        case .mixedTabsPageDefault:
            return "Mixed page and tab packages"
        case .priceVariables:
            return "Price variables"
        case .offerPriceVariables:
            return "Offer price variables"
        }
    }

    var componentsData: PaywallComponentsData {
        switch self {
        case .iconOnlyButton:
            return Self.iconOnlyButtonComponentsData()
        case .mixedTabsPageDefault:
            return Self.mixedTabsPageDefaultComponentsData()
        case .priceVariables:
            return Self.variableListComponentsData(
                templateName: "fixture-price-variables",
                variables: Self.priceVariableNames
            )
        case .offerPriceVariables:
            return Self.variableListComponentsData(
                templateName: "fixture-offer-price-variables",
                variables: Self.offerPriceVariableNames
            )
        }
    }

    /// A component referencing a package the offering lacks renders with no product.
    var packages: [Package] {
        switch self {
        case .iconOnlyButton:
            return [Self.monthlyPackage(offeringIdentifier: self.rawValue)]
        case .mixedTabsPageDefault:
            return [
                Self.annualPackage(offeringIdentifier: self.rawValue),
                Self.monthlyPackage(offeringIdentifier: self.rawValue),
                Self.weeklyPackage(offeringIdentifier: self.rawValue),
                Self.lifetimePackage(offeringIdentifier: self.rawValue)
            ]
        case .priceVariables:
            return [Self.isoCodePricePackage(offeringIdentifier: self.rawValue, withOffer: false)]
        case .offerPriceVariables:
            return [Self.isoCodePricePackage(offeringIdentifier: self.rawValue, withOffer: true)]
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
            availablePackages: self.packages,
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

    /// Every base currency and price variable, in the order they render.
    static let priceVariableNames = [
        "product.currency_code",
        "product.currency_symbol",
        "product.price",
        "product.price_per_period",
        "product.price_per_period_abbreviated",
        "product.price_per_day",
        "product.price_per_week",
        "product.price_per_month",
        "product.price_per_year",
        "product.periodly"
    ]

    /// The offer-price variables, which read the discount rather than the product.
    static let offerPriceVariableNames = [
        "product.currency_symbol",
        "product.offer_price",
        "product.offer_price_per_day",
        "product.offer_price_per_week",
        "product.offer_price_per_month",
        "product.offer_price_per_year",
        "product.secondary_offer_price"
    ]

    /// An annual product priced the way the Ukraine storefront presents USD: Apple's displayed
    /// price spells the currency `USD`, while the product's `NumberFormatter` spells it `US$`.
    /// Those two spellings are what the price variables disagree over, so every rendered value
    /// below is pinned against a real divergence rather than a tidy `$4.99`.
    static func isoCodePricePackage(offeringIdentifier: String, withOffer: Bool) -> Package {
        let introductoryOffer = TestStoreProductDiscount(
            identifier: "intro",
            price: 9.99,
            localizedPriceString: "9,99 USD",
            paymentMode: .payUpFront,
            subscriptionPeriod: .init(value: 1, unit: .month),
            numberOfPeriods: 1,
            type: .introductory
        )

        let product = TestStoreProduct(
            localizedTitle: "Annual",
            price: 79.99,
            currencyCode: "USD",
            localizedPriceString: "79,99 USD",
            productIdentifier: "com.revenuecat.fixtures.iso_code_annual",
            productType: .autoRenewableSubscription,
            localizedDescription: "Annual plan",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .year),
            introductoryDiscount: withOffer ? introductoryOffer : nil,
            locale: Locale(identifier: "en_UA")
        )

        return Package(
            identifier: "$rc_annual",
            packageType: .annual,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: offeringIdentifier,
            webCheckoutUrl: nil
        )
    }

    /// One text row per variable, each rendered as `name=value` so a UI test reads the resolved
    /// value straight off the accessibility tree.
    static func variableListComponentsData(
        templateName: String,
        variables: [String]
    ) -> PaywallComponentsData {
        // Price variables resolve against the selected package, so a paywall with no package
        // component renders every one of them empty. The card supplies that context.
        let rows: [PaywallComponent] = [
            Self.packageCard(packageID: "$rc_annual", label: "annual", isSelectedByDefault: true)
        ] + variables.map { name in
            .text(.init(
                text: name,
                color: .init(light: .hex("#000000")),
                fontSize: 13
            ))
        }

        var localizations = variables.reduce(into: PaywallComponent.LocalizationDictionary()) {
            $0[$1] = .string("\($1)={{ \($1) }}")
        }
        localizations["annual"] = .string("Annual")
        localizations["annual_selected"] = .string("Annual selected")

        return .init(
            templateName: templateName,
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: rows,
                    dimension: .vertical(.leading, .start),
                    size: .init(width: .fill, height: .fill),
                    spacing: 6,
                    backgroundColor: .init(light: .hex("#ffffff")),
                    padding: .init(top: 80, bottom: 24, leading: 16, trailing: 16)
                ),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: ["en_US": localizations],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

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

    static func annualPackage(offeringIdentifier: String) -> Package {
        return Self.package(
            identifier: "$rc_annual",
            packageType: .annual,
            title: "Annual",
            price: 39.99,
            priceString: "$39.99",
            period: .init(value: 1, unit: .year),
            offeringIdentifier: offeringIdentifier
        )
    }

    static func weeklyPackage(offeringIdentifier: String) -> Package {
        return Self.package(
            identifier: "$rc_weekly",
            packageType: .weekly,
            title: "Weekly",
            price: 1.99,
            priceString: "$1.99",
            period: .init(value: 1, unit: .week),
            offeringIdentifier: offeringIdentifier
        )
    }

    static func lifetimePackage(offeringIdentifier: String) -> Package {
        return Self.package(
            identifier: "$rc_lifetime",
            packageType: .lifetime,
            title: "Lifetime",
            price: 99.99,
            priceString: "$99.99",
            period: nil,
            offeringIdentifier: offeringIdentifier
        )
    }

    // swiftlint:disable:next function_parameter_count
    static func package(
        identifier: String,
        packageType: PackageType,
        title: String,
        price: Decimal,
        priceString: String,
        period: SubscriptionPeriod?,
        offeringIdentifier: String
    ) -> Package {
        let product = TestStoreProduct(
            localizedTitle: title,
            price: price,
            localizedPriceString: priceString,
            productIdentifier: "com.revenuecat.fixtures.\(identifier)",
            productType: period == nil ? .nonConsumable : .autoRenewableSubscription,
            localizedDescription: "\(title) plan",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: period
        )

        return Package(
            identifier: identifier,
            packageType: packageType,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: offeringIdentifier,
            webCheckoutUrl: nil
        )
    }

    /// `visible: false` hides the card, standing in for a rule that resolves hidden.
    static func packageCard(
        packageID: String,
        label: String,
        isSelectedByDefault: Bool,
        visible: Bool? = nil
    ) -> PaywallComponent {
        return .package(.init(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            visible: visible,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [
                    .text(.init(
                        text: label,
                        color: .init(light: .hex("#000000")),
                        overrides: [
                            .init(
                                extendedConditions: [.selected],
                                properties: .init(text: "\(label)_selected")
                            )
                        ]
                    ))
                ],
                size: .init(width: .fill, height: .fit(nil)),
                padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12)
            )
        ))
    }

    /// Two page packages with the default among them hidden, plus two tabs declaring their own.
    static func mixedTabsPageDefaultComponentsData() -> PaywallComponentsData {
        let tabs: PaywallComponent = .tabs(.init(
            control: .init(
                type: .buttons,
                stack: .init(components: [
                    .tabControlButton(.init(tabId: "tab_weekly", stack: .init(components: [
                        .text(.init(text: "tab_weekly_button", color: .init(light: .hex("#000000"))))
                    ]))),
                    .tabControlButton(.init(tabId: "tab_lifetime", stack: .init(components: [
                        .text(.init(text: "tab_lifetime_button", color: .init(light: .hex("#000000"))))
                    ])))
                ])
            ),
            tabs: [
                .init(id: "tab_weekly", stack: .init(components: [
                    .tabControl(.init()),
                    Self.packageCard(packageID: "$rc_weekly", label: "weekly", isSelectedByDefault: true)
                ])),
                .init(id: "tab_lifetime", stack: .init(components: [
                    .tabControl(.init()),
                    Self.packageCard(packageID: "$rc_lifetime", label: "lifetime", isSelectedByDefault: true)
                ]))
            ],
            defaultTabId: "tab_weekly"
        ))

        return .init(
            templateName: "fixture-mixed-tabs-page-default",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [
                        // The authored default, hidden: nothing should end up selected on it.
                        Self.packageCard(
                            packageID: "$rc_annual",
                            label: "annual",
                            isSelectedByDefault: true,
                            visible: false
                        ),
                        Self.packageCard(
                            packageID: "$rc_monthly",
                            label: "monthly",
                            isSelectedByDefault: false
                        ),
                        tabs
                    ],
                    dimension: .vertical(.center, .start),
                    size: .init(width: .fill, height: .fill),
                    spacing: 16,
                    backgroundColor: .init(light: .hex("#ffffff")),
                    padding: .init(top: 60, bottom: 24, leading: 16, trailing: 16)
                ),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            )),
            componentsLocalizations: [
                "en_US": [
                    "annual": .string("Annual"),
                    "annual_selected": .string("Annual selected"),
                    "monthly": .string("Monthly"),
                    "monthly_selected": .string("Monthly selected"),
                    "weekly": .string("Weekly"),
                    "weekly_selected": .string("Weekly selected"),
                    "lifetime": .string("Lifetime"),
                    "lifetime_selected": .string("Lifetime selected"),
                    "tab_weekly_button": .string("Weekly tab"),
                    "tab_lifetime_button": .string("Lifetime tab")
                ]
            ],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
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
