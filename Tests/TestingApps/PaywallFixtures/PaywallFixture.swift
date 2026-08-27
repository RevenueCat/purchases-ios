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

    /// One badge rule per offer type, each badge carrying its own rule for its copy. A customer
    /// matching both gets the later rule's badge, so it must show that badge's own copy.
    case badgeRulesPerOffer = "badge_rules_per_offer"

    var title: String {
        switch self {
        case .iconOnlyButton:
            return "Icon-only button"
        case .mixedTabsPageDefault:
            return "Mixed page and tab packages"
        case .badgeRulesPerOffer:
            return "Badge rules per offer type"
        }
    }

    var componentsData: PaywallComponentsData {
        switch self {
        case .iconOnlyButton:
            return Self.iconOnlyButtonComponentsData()
        case .mixedTabsPageDefault:
            return Self.mixedTabsPageDefaultComponentsData()
        case .badgeRulesPerOffer:
            return Self.badgeRulesPerOfferComponentsData()
        }
    }

    /// A component referencing a package the offering lacks renders with no product.
    var packages: [Package] {
        switch self {
        case .iconOnlyButton:
            return [Self.monthlyPackage(offeringIdentifier: self.rawValue)]
        case .badgeRulesPerOffer:
            return [Self.annualPackageWithPromoOffer(offeringIdentifier: self.rawValue)]
        case .mixedTabsPageDefault:
            return [
                Self.annualPackage(offeringIdentifier: self.rawValue),
                Self.monthlyPackage(offeringIdentifier: self.rawValue),
                Self.weeklyPackage(offeringIdentifier: self.rawValue),
                Self.lifetimePackage(offeringIdentifier: self.rawValue)
            ]
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

    /// Carries a `.promotional` discount matching the badge rule's offer code, which is what the
    /// simulated promo cache looks for.
    static func annualPackageWithPromoOffer(offeringIdentifier: String) -> Package {
        let promo = TestStoreProductDiscount(
            identifier: Self.promoOfferCode,
            price: 9.99,
            localizedPriceString: "$9.99",
            paymentMode: .payUpFront,
            subscriptionPeriod: .init(value: 1, unit: .year),
            numberOfPeriods: 1,
            type: .promotional
        )
        let product = TestStoreProduct(
            localizedTitle: "Annual",
            price: 39.99,
            localizedPriceString: "$39.99",
            productIdentifier: "com.revenuecat.fixtures.annual.promo",
            productType: .autoRenewableSubscription,
            localizedDescription: "Annual subscription",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .year),
            discounts: [promo]
        )

        return Package(
            identifier: "$rc_annual",
            packageType: .annual,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: offeringIdentifier,
            webCheckoutUrl: nil
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

    static let promoOfferCode = "fixture_promo_offer"

    /// A package row with no badge of its own, gaining one from each offer rule. Both badges carry
    /// the same placeholder copy in their base and their real copy behind their own rule, which is
    /// how the dashboard authors them.
    static func badgeRulesPerOfferComponentsData() -> PaywallComponentsData {
        func badge(baseLid: String, resolvedLid: String, condition: PaywallComponent.Condition)
        -> PaywallComponent.Badge {
            return .init(
                style: .overlaid,
                alignment: .topTrailing,
                stack: .init(
                    components: [
                        .text(.init(
                            text: baseLid,
                            color: .init(light: .hex("#ffffff")),
                            overrides: [
                                .init(conditions: [condition], properties: .init(text: resolvedLid))
                            ]
                        ))
                    ],
                    size: .init(width: .fit(nil), height: .fit(nil)),
                    backgroundColor: .init(light: .hex("#aa00ff")),
                    padding: .init(top: 4, bottom: 4, leading: 8, trailing: 8)
                )
            )
        }

        return .init(
            templateName: "fixture-badge-rules-per-offer",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [
                        .package(.init(
                            packageID: "$rc_annual",
                            isSelectedByDefault: true,
                            applePromoOfferProductCode: Self.promoOfferCode,
                            stack: .init(
                                components: [
                                    .text(.init(
                                        text: "annual",
                                        color: .init(light: .hex("#000000"))
                                    ))
                                ],
                                size: .init(width: .fill, height: .fit(nil)),
                                backgroundColor: .init(light: .hex("#eeeeee")),
                                padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16),
                                overrides: [
                                    .init(
                                        conditions: [.introOffer],
                                        properties: .init(badge: badge(
                                            baseLid: "badge_placeholder",
                                            resolvedLid: "badge_trial",
                                            condition: .introOffer
                                        ))
                                    ),
                                    .init(
                                        conditions: [.promoOffer],
                                        properties: .init(badge: badge(
                                            baseLid: "badge_placeholder",
                                            resolvedLid: "badge_promo",
                                            condition: .promoOffer
                                        ))
                                    )
                                ]
                            )
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
                    "annual": .string("Annual"),
                    "badge_placeholder": .string("Badge"),
                    "badge_trial": .string("TRIAL BADGE"),
                    "badge_promo": .string("PROMO BADGE")
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
