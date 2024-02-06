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

#if !os(macOS) && !os(tvOS)

/// Presentation options to use with the [presentPaywallIfNeeded](x-source-tag://presentPaywallIfNeeded) View modifiers.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
public enum PaywallPresentationMode {

    /// Paywall presented using SwiftUI's `.sheet`.
    case sheet

    /// Paywall presented using SwiftUI's `.fullScreenCover`.
    case fullScreen

}

extension PaywallPresentationMode {

    // swiftlint:disable:next missing_docs
    public static let `default`: Self = .sheet

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// If `nil` (the default), `Offerings.current` will be used. Note that specifying this parameter means
    /// that it will ignore the offering configured in an active experiment.
    /// - Parameter fonts: An optional ``PaywallFontProvider``.
    /// - Parameter presentationMode: The desired presentation mode of the paywall. Defaults to `.sheet`.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    ///
    /// - Tag: presentPaywallIfNeeded
    public func presentPaywallIfNeeded(
        requiredEntitlementIdentifier: String,
        offering: Offering? = nil,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        presentationMode: PaywallPresentationMode = .default,
        purchaseStarted: PurchaseStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            offering: offering,
            fonts: fonts,
            presentationMode: presentationMode,
            shouldDisplay: { info in
                !info.entitlements
                    .activeInCurrentEnvironment
                    .keys
                    .contains(requiredEntitlementIdentifier)
            },
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure,
            onDismiss: onDismiss
        )
    }

    /// Presents a ``PaywallView`` based a given condition.
    /// Example:
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNeeded {
    ///         !$0.entitlements.active.keys.contains("entitlement_identifier")
    ///     } purchaseStarted: {
    ///         print("Purchase started")
    ///     } purchaseCompleted: { customerInfo in
    ///         print("Customer info unlocked entitlement: \(customerInfo.entitlements)")
    ///     } purchaseCancelled: {
    ///         print("Purchase was cancelled")
    ///     } restoreCompleted: { customerInfo in
    ///         // If `entitlement_identifier` is active, paywall will dismiss automatically.
    ///         print("Purchases restored")
    ///     } purchaseFailure: { error in
    ///         print("Error purchasing: \(error)")
    ///     } restoreFailure: { error in
    ///         print("Error restoring purchases: \(error)")
    ///     } onDismiss: {
    ///         print("Paywall was dismissed either manually or automatically after a purchase.")
    ///     }
    /// }
    /// ```
    /// - Note: If loading the `CustomerInfo` fails (for example, if Internet is offline),
    /// the paywall won't be displayed.
    ///
    /// - Parameter offering: The `Offering` containing the desired `PaywallData` to display.
    /// If `nil` (the default), `Offerings.current` will be used. Note that specifying this parameter means
    /// that it will ignore the offering configured in an active experiment.
    /// - Parameter fonts: An optional ``PaywallFontProvider``.
    /// - Parameter presentationMode: The desired presentation mode of the paywall. Defaults to `.sheet`.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func presentPaywallIfNeeded(
        offering: Offering? = nil,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        presentationMode: PaywallPresentationMode = .default,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseStarted: PurchaseStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            offering: offering,
            fonts: fonts,
            presentationMode: presentationMode,
            shouldDisplay: shouldDisplay,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure,
            onDismiss: onDismiss,
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
        presentationMode: PaywallPresentationMode = .default,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseStarted: PurchaseStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil,
        customerInfoFetcher: @escaping CustomerInfoFetcher
    ) -> some View {
        return self
            .modifier(PresentingPaywallModifier(
                shouldDisplay: shouldDisplay,
                presentationMode: presentationMode,
                purchaseStarted: purchaseStarted,
                purchaseCompleted: purchaseCompleted,
                purchaseCancelled: purchaseCancelled,
                restoreCompleted: restoreCompleted,
                purchaseFailure: purchaseFailure,
                restoreFailure: restoreFailure,
                onDismiss: onDismiss,
                content: .optionalOffering(offering),
                fontProvider: fonts,
                customerInfoFetcher: customerInfoFetcher,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            ))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
private struct PresentingPaywallModifier: ViewModifier {

    private struct Data: Identifiable {
        var customerInfo: CustomerInfo
        var id: String { self.customerInfo.originalAppUserId }
    }

    var shouldDisplay: @Sendable (CustomerInfo) -> Bool
    var presentationMode: PaywallPresentationMode
    var purchaseStarted: PurchaseStartedHandler?
    var purchaseCompleted: PurchaseOrRestoreCompletedHandler?
    var purchaseCancelled: PurchaseCancelledHandler?
    var restoreCompleted: PurchaseOrRestoreCompletedHandler?
    var purchaseFailure: PurchaseFailureHandler?
    var restoreFailure: PurchaseFailureHandler?
    var onDismiss: (() -> Void)?

    var content: PaywallViewConfiguration.Content
    var fontProvider: PaywallFontProvider

    var customerInfoFetcher: View.CustomerInfoFetcher
    var introEligibility: TrialOrIntroEligibilityChecker?

    init(
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        presentationMode: PaywallPresentationMode,
        purchaseStarted: PurchaseStartedHandler?,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler?,
        purchaseCancelled: PurchaseCancelledHandler?,
        restoreCompleted: PurchaseOrRestoreCompletedHandler?,
        purchaseFailure: PurchaseFailureHandler?,
        restoreFailure: PurchaseFailureHandler?,
        onDismiss: (() -> Void)?,
        content: PaywallViewConfiguration.Content,
        fontProvider: PaywallFontProvider,
        customerInfoFetcher: @escaping View.CustomerInfoFetcher,
        introEligibility: TrialOrIntroEligibilityChecker?,
        purchaseHandler: PurchaseHandler?
    ) {
        self.shouldDisplay = shouldDisplay
        self.presentationMode = presentationMode
        self.purchaseStarted = purchaseStarted
        self.purchaseCompleted = purchaseCompleted
        self.purchaseCancelled = purchaseCancelled
        self.restoreCompleted = restoreCompleted
        self.purchaseFailure = purchaseFailure
        self.restoreFailure = restoreFailure
        self.onDismiss = onDismiss
        self.content = content
        self.fontProvider = fontProvider
        self.customerInfoFetcher = customerInfoFetcher
        self.introEligibility = introEligibility
        self._purchaseHandler = .init(wrappedValue: purchaseHandler ?? .default())
    }

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @State
    private var data: Data?

    func body(content: Content) -> some View {
        Group {
            switch presentationMode {
            case .sheet:
                content
                    .sheet(item: self.$data, onDismiss: self.onDismiss) { data in
                        self.paywallView(data)
                    }
            case .fullScreen:
                content
                    .fullScreenCover(item: self.$data, onDismiss: self.onDismiss) { data in
                        self.paywallView(data)
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

    private func paywallView(_ data: Data) -> some View {
        PaywallView(
            configuration: .init(
                content: self.content,
                customerInfo: data.customerInfo,
                fonts: self.fontProvider,
                displayCloseButton: true,
                introEligibility: self.introEligibility,
                purchaseHandler: self.purchaseHandler
            )
        )
        .onPurchaseStarted {
            self.purchaseStarted?()
        }
        .onPurchaseCompleted {
            self.purchaseCompleted?($0)
        }
        .onPurchaseCancelled {
            self.purchaseCancelled?()
        }
        .onRestoreCompleted { customerInfo in
            self.restoreCompleted?(customerInfo)

            if !self.shouldDisplay(customerInfo) {
                self.close()
            }
        }
        .onPurchaseFailure {
            self.purchaseFailure?($0)
        }
        .onRestoreFailure {
            self.restoreFailure?($0)
        }
        .interactiveDismissDisabled(self.purchaseHandler.actionInProgress)
    }

    private func close() {
        Logger.debug(Strings.dismissing_paywall)

        self.data = nil
    }

}

#endif
