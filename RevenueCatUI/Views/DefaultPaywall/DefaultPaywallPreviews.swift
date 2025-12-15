//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultPaywallPreviews.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

#if DEBUG

#if canImport(AppKit)
import AppKit
#endif
import RevenueCat
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallPreviews: PreviewProvider {

    static let offering = Offering(
        identifier: "one",
        serverDescription: "Offering 1",
        availablePackages: [
            .init(
                identifier: "one",
                packageType: .annual,
                storeProduct: PurchaseInformationFixtures
                    .product(id: "one", title: "Annual", duration: .year, price: 99.99),
                offeringIdentifier: "org one",
                webCheckoutUrl: nil
            ),
            .init(
                identifier: "two",
                packageType: .monthly,
                storeProduct: PurchaseInformationFixtures
                    .product(id: "two", title: "Monthly", duration: .month, price: 8.99),
                offeringIdentifier: "org one",
                webCheckoutUrl: nil
            )
        ],
        webCheckoutUrl: nil
    )

    static var previews: some View {
        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .previewDisplayName("Fallback Paywall R/G")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Fallback Paywall R/G Dark")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.blueGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .previewDisplayName("Fallback Paywall B/G")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.blueGreen.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Fallback Paywall B/G Dark")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.white)
        .previewDisplayName("Fallback Paywall P/O")

        DefaultPaywallView(
            handler: .mock(),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Fallback Paywall P/O Dark")

        DefaultPaywallView(
            handler: .mock(),
            warning: .missingLocalization,
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - localization")

        DefaultPaywallView(
            handler: .mock(),
            warning: .missingLocalization,
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - localization Dark")

        DefaultPaywallView(
            handler: .mock(),
            warning: .noPaywall("WAT"),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.redGreen.toAppIconDetailprovider()
        )
        .background(Color.white)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - no paywall")

        DefaultPaywallView(
            handler: .mock(),
            warning: .noPaywall("WAT"),
            offering: offering,
            appName: "RevenueCat",
            iconDetailProvider: DualColorImageGenerator.purpleOrange.toAppIconDetailprovider()
        )
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .accentColor(.yellow)
        .previewDisplayName("Warning Paywall - no paywall Dark")
    }
}

#endif
