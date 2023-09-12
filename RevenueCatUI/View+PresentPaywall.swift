//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PresentPaywall.swift
//
//  Created by Nacho Soto on 7/24/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
extension View {

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo

    /// Presents a ``PaywallView`` if the given entitlement identifier is not active
    /// in the current environment for the current `CustomerInfo`.
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNeeded(requiredEntitlementIdentifier: "pro")
    /// }
    /// ```
    /// - Note: If loading the `CustomerInfo` fails (for example, if Internet is offline),
    /// the paywall won't be displayed.
    /// 
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func presentPaywallIfNeeded(
        requiredEntitlementIdentifier: String,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            shouldDisplay: { info in
                !info.entitlements
                    .activeInCurrentEnvironment
                    .keys
                    .contains(requiredEntitlementIdentifier)
            },
            purchaseCompleted: purchaseCompleted,
            restoreCompleted: restoreCompleted
        )
    }

    /// Presents a ``PaywallView`` based a given condition.
    /// Example:
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNeeded {
    ///         !$0.entitlements.active.keys.contains("entitlement_identifier")
    ///     } purchaseCompleted: { customerInfo in
    ///         print("Customer info unlocked entitlement: \(customerInfo.entitlements)")
    ///     } restoreCompleted: { customerInfo in
    ///         // If `entitlement_identifier` is active, paywall will dismiss automatically.
    ///         print("Purchases restored")
    ///     }
    /// }
    /// ```
    /// - Note: If loading the `CustomerInfo` fails (for example, if Internet is offline),
    /// the paywall won't be displayed.
    public func presentPaywallIfNeeded(
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            shouldDisplay: shouldDisplay,
            purchaseCompleted: purchaseCompleted,
            restoreCompleted: restoreCompleted,
            customerInfoFetcher: {
                guard Purchases.isConfigured else {
                    throw PaywallError.purchasesNotConfigured
                }

                return try await Purchases.shared.customerInfo()
            }
        )
    }

    // Visible overload for tests
    func presentPaywallIfNeeded(
        offering: Offering? = nil,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler? = nil,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        customerInfoFetcher: @escaping CustomerInfoFetcher
    ) -> some View {
        return self
            .modifier(PresentingPaywallModifier(
                shouldDisplay: shouldDisplay,
                purchaseCompleted: purchaseCompleted,
                restoreCompleted: restoreCompleted,
                offering: offering,
                fontProvider: fonts,
                customerInfoFetcher: customerInfoFetcher,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            ))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
private struct PresentingPaywallModifier: ViewModifier {

    private struct Data: Identifiable {
        var customerInfo: CustomerInfo
        var id: String { self.customerInfo.originalAppUserId }
    }

    var shouldDisplay: @Sendable (CustomerInfo) -> Bool
    var purchaseCompleted: PurchaseOrRestoreCompletedHandler?
    var restoreCompleted: PurchaseOrRestoreCompletedHandler?
    var offering: Offering?
    var fontProvider: PaywallFontProvider

    var customerInfoFetcher: View.CustomerInfoFetcher
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

    @State
    private var data: Data?

    func body(content: Content) -> some View {
        content
            .sheet(item: self.$data) { data in
                NavigationView {
                    PaywallView(
                        offering: self.offering,
                        customerInfo: data.customerInfo,
                        fonts: self.fontProvider,
                        introEligibility: self.introEligibility ?? .default(),
                        purchaseHandler: self.purchaseHandler ?? .default()
                    )
                    .onPurchaseCompleted {
                        self.purchaseCompleted?($0)

                        self.close()
                    }
                    .onRestoreCompleted { customerInfo in
                        self.restoreCompleted?(customerInfo)

                        if !self.shouldDisplay(customerInfo) {
                            self.close()
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            Button {
                                self.close()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
            }
            .task {
                guard let info = try? await self.customerInfoFetcher() else { return }

                Logger.debug(Strings.determining_whether_to_display_paywall)

                if self.shouldDisplay(info) {
                    Logger.debug(Strings.displaying_paywall)

                    self.data = .init(customerInfo: info)
                } else {
                    Logger.debug(Strings.not_displaying_paywall)
                }
            }
    }

    private func close() {
        self.data = nil

        Logger.debug(Strings.dismissing_paywall)
    }

}
