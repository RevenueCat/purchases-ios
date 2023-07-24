//
//  View+PresentPaywall.swift
//  
//
//  Created by Nacho Soto on 7/24/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension View {

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
        mode: PaywallViewMode = .default,
        requiredEntitlementIdentifier: String
    ) -> some View {
        return self.presentPaywallIfNecessary { info in
            !info.entitlements
                .activeInCurrentEnvironment
                .keys
                .contains(requiredEntitlementIdentifier)
        }
    }

    /// Presents a ``PaywallView`` based a given condition.
    /// Example:
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNecessary { !$0.entitlements.active.keys.contains("entitlement_identifier") }
    /// }
    /// ```
    /// - Note: If loading the `CustomerInfo` fails (for example, if Internet is offline),
    /// the paywall won't be displayed.
    public func presentPaywallIfNecessary(
        mode: PaywallViewMode = .default,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool
    ) -> some View {
        return self
            .modifier(PresentingPaywallModifier(
                shouldDisplay: shouldDisplay,
                mode: mode
            ))
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct PresentingPaywallModifier: ViewModifier {

    var shouldDisplay: @Sendable (CustomerInfo) -> Bool
    var mode: PaywallViewMode

    @State
    private var isDisplayed = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$isDisplayed) {
                PaywallView(mode: self.mode)
            }
            .task {
                guard let info = try? await Purchases.shared.customerInfo() else { return }
                if self.shouldDisplay(info) {
                    self.isDisplayed = true
                }
            }
    }

}
