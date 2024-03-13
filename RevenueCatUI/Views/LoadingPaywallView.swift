//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LoadingPaywallView.swift
//
//  Created by Nacho Soto on 7/21/23.

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS)

/// A `PaywallView` suitable to be displayed as a loading placeholder.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@MainActor
struct LoadingPaywallView: View {

    var mode: PaywallViewMode
    var displayCloseButton: Bool

    var shimmer: Bool = true

    var body: some View {
        LoadedOfferingPaywallView(
            offering: .init(
                identifier: Self.offeringIdentifier,
                serverDescription: "",
                metadata: [:],
                paywall: Self.paywall,
                availablePackages: Self.packages
            ),
            activelySubscribedProductIdentifiers: [],
            paywall: Self.defaultPaywall,
            template: Self.template,
            mode: self.mode,
            fonts: DefaultPaywallFontProvider(),
            displayCloseButton: self.displayCloseButton,
            introEligibility: Self.introEligibility,
            purchaseHandler: Self.purchaseHandler
        )
        .allowsHitTesting(false)
        .redacted(reason: .placeholder)
        .shimmering(enable: self.mode.shouldDisplayBackground && self.shimmer)
        .background {
            TemplateBackgroundImageView(
                url: Self.defaultPaywall.backgroundImageURL,
                blurred: true,
                ignoreSafeArea: self.mode.shouldDisplayBackground
            )
        }
    }

    private static let template: PaywallTemplate = PaywallData.defaultTemplate
    private static let defaultPaywall: PaywallData = .createDefault(with: Self.packages, locale: .current)

    private static let paywall: PaywallData = {
        var paywall: PaywallData = Self.defaultPaywall
        // Hide background so it doesn't get shimmer
        paywall.config.images.background = nil

        return paywall
    }()

    private static let packages: [Package] = [
        Self.monthlyPackage,
        Self.weeklyPackage,
        Self.annualPackage
    ]

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
private extension LoadingPaywallView {

    static let introEligibility: TrialOrIntroEligibilityChecker = .init(checker: { packages in
        return Dictionary(
            uniqueKeysWithValues: packages.map { ($0, .unknown) }
        )
    })
    static let purchaseHandler: PurchaseHandler = .init(purchases: LoadingPaywallPurchases())

    static let offeringIdentifier = "offering"
    static let weeklyPackage = Package(
        identifier: "weekly",
        packageType: .weekly,
        storeProduct: Self.weeklyProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let monthlyPackage = Package(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: Self.monthlyProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let annualPackage = Package(
        identifier: "annual",
        packageType: .annual,
        storeProduct: Self.annualProduct.toStoreProduct(),
        offeringIdentifier: Self.offeringIdentifier
    )
    static let weeklyProduct = TestStoreProduct(
        localizedTitle: "Weekly",
        price: 1.99,
        localizedPriceString: "$1.99",
        productIdentifier: "com.revenuecat.product_1",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO weekly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .week)
    )
    static let monthlyProduct = TestStoreProduct(
        localizedTitle: "Monthly",
        price: 12.99,
        localizedPriceString: "$12.99",
        productIdentifier: "com.revenuecat.product_2",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO monthly",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .month)
    )
    static let annualProduct = TestStoreProduct(
        localizedTitle: "Annual",
        price: 69.49,
        localizedPriceString: "$69.49",
        productIdentifier: "com.revenuecat.product_3",
        productType: .autoRenewableSubscription,
        localizedDescription: "PRO annual",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year)
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private final class LoadingPaywallPurchases: PaywallPurchasesType {

    func purchase(package: Package) async throws -> PurchaseResultData {
        fatalError("Should not be able to purchase")
    }

    func restorePurchases() async throws -> CustomerInfo {
        fatalError("Should not be able to purchase")
    }

    func track(paywallEvent: PaywallEvent) async {
        // Ignoring events from loading paywall view
    }

}

// MARK: - Shimmer

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct Shimmer: ViewModifier {

    var duration: CGFloat
    var autoreverse: Bool

    @State
    private var initialState: Bool = true

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: .init(colors: [
                        .black.opacity(0.3),
                        .black,
                        .black.opacity(0.3)
                    ]),
                    startPoint: self.startPoint,
                    endPoint: self.endPoint
                )
                .edgesIgnoringSafeArea(.all)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: self.duration)
                    .delay(self.duration / 2.0)
                    .repeatForever(autoreverses: self.autoreverse)
                ) {
                    self.initialState.toggle()
                }
            }
    }

    private var startPoint: UnitPoint {
        return self.initialState ? UnitPoint(x: -0.3, y: -0.3) : UnitPoint(x: 1, y: 1)
    }

    private var endPoint: UnitPoint {
        return self.initialState ? UnitPoint(x: 0, y: 0) : UnitPoint(x: 1.3, y: 1.3)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension View {

    @ViewBuilder
    func shimmering(
        enable: Bool,
        duration: Double = 1.5,
        autoreverse: Bool = false
    ) -> some View {
        if enable {
            self.modifier(Shimmer(duration: duration, autoreverse: autoreverse))
        } else {
            self
        }
    }

}

// MARK: -

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
struct LoadingPaywallView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(PaywallViewMode.allCases, id: \.self) { mode in
            LoadingPaywallView(mode: mode, displayCloseButton: true)
                .previewDisplayName("\(mode)")
        }
    }

}

#endif

#endif
