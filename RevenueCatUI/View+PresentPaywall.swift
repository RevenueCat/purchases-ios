//
//  View+PresentPaywall.swift
//  
//
//  Created by Nacho Soto on 7/24/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
extension View {

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo

    /// Presents a ``PaywallView`` if the given entitlement identifier is not active
    /// in the current environment for the current `CustomerInfo`.
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNecessary(requiredEntitlementIdentifier: "pro")
    /// }
    /// ```
    /// - Note: If loading the `CustomerInfo` fails (for example, if Internet is offline),
    /// the paywall won't be displayed.
    public func presentPaywallIfNecessary(
        requiredEntitlementIdentifier: String,
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.presentPaywallIfNecessary(
            shouldDisplay: { info in
                !info.entitlements
                    .activeInCurrentEnvironment
                    .keys
                    .contains(requiredEntitlementIdentifier)
            },
            purchaseCompleted: purchaseCompleted
        )
    }

    /// Presents a ``PaywallView`` based a given condition.
    /// Example:
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNecessary {
    ///         !$0.entitlements.active.keys.contains("entitlement_identifier")
    ///     } purchaseCompleted: { customerInfo in
    ///         print("Customer info unlocked entitlement: \(customerInfo.entitlements)")
    ///     }
    /// }
    /// ```
    /// - Note: If loading the `CustomerInfo` fails (for example, if Internet is offline),
    /// the paywall won't be displayed.
    public func presentPaywallIfNecessary(
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseCompleted: PurchaseCompletedHandler? = nil
    ) -> some View {
        return self.presentPaywallIfNecessary(
            shouldDisplay: shouldDisplay,
            purchaseCompleted: purchaseCompleted,
            customerInfoFetcher: {
                guard Purchases.isConfigured else {
                    throw PaywallError.purchasesNotConfigured
                }

                return try await Purchases.shared.customerInfo()
            }
        )
    }

    // Visible overload for tests
    func presentPaywallIfNecessary(
        offering: Offering? = nil,
        introEligibility: TrialOrIntroEligibilityChecker? = nil,
        purchaseHandler: PurchaseHandler? = nil,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseCompleted: PurchaseCompletedHandler? = nil,
        customerInfoFetcher: @escaping CustomerInfoFetcher
    ) -> some View {
        return self
            .modifier(PresentingPaywallModifier(
                shouldDisplay: shouldDisplay,
                purchaseCompleted: purchaseCompleted,
                offering: offering,
                customerInfoFetcher: customerInfoFetcher,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            ))
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(macOS, unavailable, message: "RevenueCatUI does not support macOS yet")
private struct PresentingPaywallModifier: ViewModifier {

    var shouldDisplay: @Sendable (CustomerInfo) -> Bool
    var purchaseCompleted: PurchaseCompletedHandler?
    var offering: Offering?

    var customerInfoFetcher: View.CustomerInfoFetcher
    var introEligibility: TrialOrIntroEligibilityChecker?
    var purchaseHandler: PurchaseHandler?

    @State
    private var isDisplayed = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$isDisplayed) {
                NavigationView {
                    PaywallView(
                        offering: self.offering,
                        introEligibility: self.introEligibility ?? .default(),
                        purchaseHandler: self.purchaseHandler ?? .default()
                    )
                    .onPurchaseCompleted {
                        self.purchaseCompleted?($0)
                    }
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            Button {
                                self.isDisplayed = false
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

                    self.isDisplayed = true
                } else {
                    Logger.debug(Strings.not_displaying_paywall)
                }
            }
    }

}
