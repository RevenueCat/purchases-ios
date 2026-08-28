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

    /// Decorative media in every place a real paywall puts it: a logo image component, feature
    /// rows with checkmark icons, package cards with a checkmark icon inside the selector
    /// button, and a background image. Tests assert which of them reach the accessibility tree.
    case decorativeMedia = "decorative_media"

    var title: String {
        switch self {
        case .iconOnlyButton:
            return "Icon-only button"
        case .mixedTabsPageDefault:
            return "Mixed page and tab packages"
        case .decorativeMedia:
            return "Decorative media"
        }
    }

    var componentsData: PaywallComponentsData {
        switch self {
        case .iconOnlyButton:
            return Self.iconOnlyButtonComponentsData()
        case .mixedTabsPageDefault:
            return Self.mixedTabsPageDefaultComponentsData()
        case .decorativeMedia:
            return Self.decorativeMediaComponentsData()
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
        case .decorativeMedia:
            return [
                Self.annualPackage(offeringIdentifier: self.rawValue),
                Self.monthlyPackage(offeringIdentifier: self.rawValue),
                Self.weeklyPackage(offeringIdentifier: self.rawValue)
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

    /// A checkmark icon like the ones real paywalls put next to feature copy and inside
    /// package cards. Purely decorative: the adjacent text carries the meaning.
    static func checkIcon(sizePoints: CGFloat = 20) -> PaywallComponent {
        return .icon(.init(
            baseUrl: "https://icons.pawwalls.com/icons",
            iconName: "check",
            formats: .init(
                svg: "check.svg",
                png: "check.png",
                heic: "check.heic",
                webp: "check.webp"
            ),
            size: .init(width: .fixed(UInt(sizePoints)), height: .fixed(UInt(sizePoints))),
            padding: .zero,
            margin: .zero,
            color: .init(light: .hex("#000000")),
            iconBackground: nil
        ))
    }

    /// A remotely hosted photo standing in for a logo or background. The dimensions describe
    /// the asset so aspect math is stable before the download finishes.
    static let sampleImageUrls = PaywallComponent.ThemeImageUrls(
        light: .init(
            width: 1024,
            height: 1024,
            original: URL(string: "https://assets.pawwalls.com/1172568_1741034533.heic")!,
            heic: URL(string: "https://assets.pawwalls.com/1172568_1741034533.heic")!,
            heicLowRes: URL(string: "https://assets.pawwalls.com/1172568_1741034533.heic")!
        )
    )

    /// A package card shaped like a real offer button: name, price (via variables), and a
    /// decorative checkmark icon inside the selector.
    ///
    /// `hiddenLeadingText` puts an invisible text ahead of the name, standing in for a badge or
    /// promo line that resolved hidden. It renders nothing, so it must not be the one asked to
    /// speak the selection state.
    static func decoratedPackageCard(
        packageID: String,
        label: String,
        isSelectedByDefault: Bool,
        hiddenLeadingText: Bool = false
    ) -> PaywallComponent {
        return .package(.init(
            packageID: packageID,
            isSelectedByDefault: isSelectedByDefault,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [
                    .text(.init(
                        visible: !hiddenLeadingText,
                        text: hiddenLeadingText ? "hidden_badge_lid" : label,
                        color: .init(light: .hex("#000000"))
                    )),
                    .text(.init(
                        visible: hiddenLeadingText ? true : nil,
                        text: hiddenLeadingText ? label : "price_lid",
                        color: .init(light: .hex("#000000"))
                    )),
                    .text(.init(
                        text: "price_lid",
                        color: .init(light: .hex("#000000"))
                    )),
                    Self.checkIcon()
                ],
                dimension: .horizontal(.center, .start),
                size: .init(width: .fill, height: .fit(nil)),
                spacing: 8,
                padding: .init(top: 12, bottom: 12, leading: 12, trailing: 12)
            )
        ))
    }

    /// A feature row: checkmark icon plus the copy it decorates.
    static func featureRow(textLid: String) -> PaywallComponent {
        return .stack(.init(
            components: [
                Self.checkIcon(),
                .text(.init(
                    text: textLid,
                    color: .init(light: .hex("#000000"))
                ))
            ],
            dimension: .horizontal(.center, .start),
            size: .init(width: .fill, height: .fit(nil)),
            spacing: 8
        ))
    }

    static func decorativeMediaComponentsData() -> PaywallComponentsData {
        return .init(
            templateName: "fixture-decorative-media",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [
                        // Header: logo image next to the title, like a real paywall's brand mark.
                        .stack(.init(
                            components: [
                                .image(.init(
                                    source: Self.sampleImageUrls,
                                    size: .init(width: .fixed(60), height: .fixed(60))
                                )),
                                .text(.init(
                                    text: "heading_lid",
                                    color: .init(light: .hex("#000000"))
                                ))
                            ],
                            dimension: .horizontal(.center, .start),
                            size: .init(width: .fill, height: .fit(nil)),
                            spacing: 12
                        )),
                        .text(.init(
                            text: "body_lid",
                            color: .init(light: .hex("#000000"))
                        )),
                        Self.featureRow(textLid: "feature1_lid"),
                        Self.featureRow(textLid: "feature2_lid"),
                        Self.decoratedPackageCard(
                            packageID: "$rc_annual",
                            label: "annual",
                            isSelectedByDefault: true
                        ),
                        Self.decoratedPackageCard(
                            packageID: "$rc_monthly",
                            label: "monthly",
                            isSelectedByDefault: false
                        ),
                        Self.decoratedPackageCard(
                            packageID: "$rc_weekly",
                            label: "weekly",
                            isSelectedByDefault: false,
                            hiddenLeadingText: true
                        )
                    ],
                    dimension: .vertical(.center, .start),
                    size: .init(width: .fill, height: .fill),
                    spacing: 16,
                    backgroundColor: nil,
                    padding: .init(top: 60, bottom: 24, leading: 16, trailing: 16)
                ),
                stickyFooter: nil,
                background: .image(Self.sampleImageUrls, .fill, nil)
            )),
            componentsLocalizations: [
                "en_US": [
                    "heading_lid": .string("Unlock all Sundial Features"),
                    "body_lid": .string("Every feature, one subscription."),
                    "feature1_lid": .string("Create alerts for 34 solar events"),
                    "feature2_lid": .string("Full featured watch app"),
                    "annual": .string("Yearly"),
                    "monthly": .string("Monthly"),
                    "price_lid": .string("{{ product.price_per_period_abbreviated }}"),
                    "weekly": .string("Weekly"),
                    "hidden_badge_lid": .string("Hidden badge")
                ]
            ],
            revision: 1,
            defaultLocaleIdentifier: "en_US"
        )
    }

}
