//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockProduct.swift
//
//  Created by Josh Holtz on 11/14/24.

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@_spi(Internal) import RevenueCat
import StoreKit
import SwiftUI

// swiftlint:disable identifier_name

enum PreviewUIConfig {

    static func make(
        colors: [String: PaywallComponent.ColorScheme] = [:],
        fonts: [String: UIConfig.FontsConfig] = [:]
    ) -> UIConfig {
        return .init(
            app: .init(
                colors: colors,
                fonts: fonts
            ),
            localizations: [
                "en_US": [
                    "day": "day",
                    "daily": "daily",
                    "day_short": "day",
                    "week": "week",
                    "weekly": "weekly",
                    "week_short": "wk",
                    "month": "month",
                    "monthly": "monthly",
                    "month_short": "mo",
                    "year": "year",
                    "yearly": "yearly",
                    "year_short": "yr",
                    "annual": "annual",
                    "annually": "annually",
                    "annual_short": "yr",
                    "free": "free",
                    "percent": "%d%%",
                    "num_day": "%d day",
                    "num_week": "%d week",
                    "num_month": "%d month",
                    "num_year": "%d year",
                    "num_days": "%d days",
                    "num_weeks": "%d weeks",
                    "num_months": "%d months",
                    "num_years": "%d years"
                ]
            ],
            variableConfig: .init(
                variableCompatibilityMap: [:],
                functionCompatibilityMap: [:]
            )
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PreviewRequiredPaywallsV2Properties: ViewModifier {

    @MainActor
    static let defaultPackageContext = PackageContext(
        package: nil,
        variableContext: .init(packages: [])
    )

    let screenCondition: ScreenCondition
    let componentViewState: ComponentViewState
    let packageContext: PackageContext?

    func body(content: Content) -> some View {
        content
            .environmentObject(IntroOfferEligibilityContext(introEligibilityChecker: .default()))
            .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
            .environmentObject(PurchaseHandler.default())
            .environmentObject(self.packageContext ?? Self.defaultPackageContext)
            .environment(\.screenCondition, screenCondition)
            .environment(\.componentViewState, componentViewState)
            .environment(\.safeAreaInsets, EdgeInsets())
            .fixMacButtons() // Matches the properties applied in LoadedPaywallsV2View
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    func previewRequiredPaywallsV2Properties(
        screenCondition: ScreenCondition = .compact,
        componentViewState: ComponentViewState = .default,
        packageContext: PackageContext? = nil
    ) -> some View {
        self.modifier(PreviewRequiredPaywallsV2Properties(
            screenCondition: screenCondition,
            componentViewState: componentViewState,
            packageContext: packageContext
        ))
    }
}

enum PreviewMock {

    static var weeklyStandardPackage: Package = .init(
        identifier: "weekly_standard",
        packageType: .monthly,
        storeProduct: .init(sk1Product: Product(
            price: 1.99,
            unit: .week,
            localizedTitle: "Weekly Standard"
        )),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )

    static var monthlyStandardPackage: Package = .init(
        identifier: "monthly_standard",
        packageType: .monthly,
        storeProduct: .init(sk1Product: Product(
            price: 4.99,
            unit: .month,
            localizedTitle: "Monthly Standard"
        )),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )

    static var annualStandardPackage: Package = .init(
        identifier: "annual_standard",
        packageType: .annual,
        storeProduct: .init(sk1Product: Product(
            price: 49.99,
            unit: .year,
            localizedTitle: "Annual Standard"
        )),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )

    static var weeklyPremiumPackage: Package = .init(
        identifier: "weekly_premium",
        packageType: .monthly,
        storeProduct: .init(sk1Product: Product(
            price: 4.99,
            unit: .week,
            localizedTitle: "Weekly Premium"
        )),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )

    static var monthlyPremiumPackage: Package = .init(
        identifier: "monthly_premium",
        packageType: .monthly,
        storeProduct: .init(sk1Product: Product(
            price: 9.99,
            unit: .month,
            localizedTitle: "Monthly Premium"
        )),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )

    static var annualPremiumPackage: Package = .init(
        identifier: "annual_premium",
        packageType: .annual,
        storeProduct: .init(sk1Product: Product(
            price: 99.99,
            unit: .year,
            localizedTitle: "Annual Premium"
        )),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
    )

    static var uiConfig: UIConfig = .init(
        app: .init(
            colors: [:],
            fonts: [:]
        ),
        localizations: [
            "en_US": [
                "day": "day",
                "daily": "daily",
                "day_short": "day",
                "week": "week",
                "weekly": "weekly",
                "week_short": "wk",
                "month": "month",
                "monthly": "monthly",
                "month_short": "mo",
                "year": "year",
                "yearly": "yearly",
                "year_short": "yr",
                "annual": "annual",
                "annually": "annually",
                "annual_short": "yr",
                "free_price": "free",
                "percent": "%d%%",
                "num_day_zero": "%d day",
                "num_day_one": "%d day",
                "num_day_two": "%d days",
                "num_day_few": "%d days",
                "num_day_many": "%d days",
                "num_day_other": "%d days",
                "num_week_zero": "%d week",
                "num_week_one": "%d week",
                "num_week_two": "%d weeks",
                "num_week_few": "%d weeks",
                "num_week_many": "%d weeks",
                "num_week_other": "%d weeks",
                "num_month_zero": "%d month",
                "num_month_one": "%d month",
                "num_month_two": "%d months",
                "num_month_few": "%d months",
                "num_month_many": "%d months",
                "num_month_other": "%d months",
                "num_year_zero": "%d year",
                "num_year_one": "%d year",
                "num_year_two": "%d years",
                "num_year_few": "%d years",
                "num_year_many": "%d years",
                "num_year_other": "%d years"
            ]
        ],
        variableConfig: .init(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:]
        )
    )

}

extension PreviewMock {

    class Product: SK1Product, @unchecked Sendable {

        // swiftlint:disable:next nesting
        class MockSubPeriod: SKProductSubscriptionPeriod, @unchecked Sendable {

            let _unit: SKProduct.PeriodUnit

            init(unit: SKProduct.PeriodUnit) {
                self._unit = unit
            }

            override var numberOfUnits: Int {
                return 1
            }

            override var unit: SKProduct.PeriodUnit {
                return self._unit
            }

        }

        let _price: NSDecimalNumber
        let _unit: SKProduct.PeriodUnit
        let _localizedTitle: String

        init(price: NSDecimalNumber, unit: SKProduct.PeriodUnit, localizedTitle: String) {
            self._price = price
            self._unit = unit
            self._localizedTitle = localizedTitle
        }

        override var price: NSDecimalNumber {
            return self._price
        }

        override var subscriptionPeriod: SKProductSubscriptionPeriod? {
            return MockSubPeriod(unit: self._unit)
        }

        override var localizedTitle: String {
            return self._localizedTitle
        }

        override var priceLocale: Locale {
            return Locale(identifier: "en-US")
        }

    }

}

#endif

#endif
