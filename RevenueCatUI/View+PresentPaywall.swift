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

#if !os(tvOS)

/// Presentation options to use with the [presentPaywallIfNeeded](x-source-tag://presentPaywallIfNeeded) View modifiers.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
public enum PaywallPresentationMode {

    /// Paywall presented using SwiftUI's `.sheet`.
    case sheet

    /// Paywall presented using SwiftUI's `.fullScreenCover`. `.fullScreenCover` is unavailable on macOS.
    @available(macOS, unavailable)
    case fullScreen

}

extension PaywallPresentationMode {

    // swiftlint:disable:next missing_docs
    public static let `default`: Self = .sheet

}

/// Contains the `PerformPurchase` and `PerformRestore` blocks that are executed when
/// ``Purchases/purchasesAreCompletedBy`` is ``PurchasesAreCompletedBy/myApp``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct MyAppPurchaseLogic {

    /// When ``Purchases/purchasesAreCompletedBy`` is ``PurchasesAreCompletedBy/myApp``, this is the app-defined
    /// callback method that performs the purchase.
    public let performPurchase: PerformPurchase

    /// When  ``Purchases/purchasesAreCompletedBy`` is ``PurchasesAreCompletedBy/myApp``, this is the app-defined
    /// callback method that performs the restore.
    public let performRestore: PerformRestore

    /// Initializes the struct with blocks that are executed when
    /// ``Purchases/purchasesAreCompletedBy`` is ``PurchasesAreCompletedBy/myApp``.
    public init(performPurchase: @escaping PerformPurchase, performRestore: @escaping PerformRestore) {
        self.performPurchase = performPurchase
        self.performRestore = performRestore
    }
}

// swiftlint:disable file_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
extension View {

    typealias CustomerInfoFetcher = @Sendable () async throws -> CustomerInfo

    // swiftlint:disable line_length
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
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
    /// If `nil` (the default), `Offerings.current` will be used. Note that specifying this parameter means
    /// that it will ignore the offering configured in an active experiment.
    /// - Parameter fonts: An optional ``PaywallFontProvider``.
    /// - Parameter presentationMode: The desired presentation mode of the paywall. Defaults to `.sheet`.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    ///
    /// - Tag: presentPaywallIfNeeded
    @available(iOS, deprecated: 1, renamed: "presentPaywallIfNeeded(requiredEntitlementIdentifier:offering:fonts:presentationMode:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(tvOS, deprecated: 1, renamed: "presentPaywallIfNeeded(requiredEntitlementIdentifier:offering:fonts:presentationMode:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(watchOS, deprecated: 1, renamed: "presentPaywallIfNeeded(requiredEntitlementIdentifier:offering:fonts:presentationMode:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(macOS, deprecated: 1, renamed: "presentPaywallIfNeeded(requiredEntitlementIdentifier:offering:fonts:presentationMode:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(macCatalyst, deprecated: 1, renamed: "presentPaywallIfNeeded(requiredEntitlementIdentifier:offering:fonts:presentationMode:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    // swiftlint:enable line_length
    public func presentPaywallIfNeeded(
        requiredEntitlementIdentifier: String,
        offering: Offering? = nil,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        presentationMode: PaywallPresentationMode = .default,
        purchaseStarted: @escaping PurchaseStartedHandler,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            requiredEntitlementIdentifier: requiredEntitlementIdentifier,
            offering: offering,
            fonts: fonts,
            presentationMode: presentationMode,
            purchaseStarted: { _ in
                purchaseStarted()
            },
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: nil,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure,
            onDismiss: onDismiss
        )
    }

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
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
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
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            offering: offering,
            fonts: fonts,
            presentationMode: presentationMode,
            myAppPurchaseLogic: myAppPurchaseLogic,
            shouldDisplay: { info in
                !info.entitlements
                    .activeInCurrentEnvironment
                    .keys
                    .contains(requiredEntitlementIdentifier)
            },
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure,
            onDismiss: onDismiss
        )
    }

    // swiftlint:disable line_length
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
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
    /// If `nil` (the default), `Offerings.current` will be used. Note that specifying this parameter means
    /// that it will ignore the offering configured in an active experiment.
    /// - Parameter fonts: An optional ``PaywallFontProvider``.
    /// - Parameter presentationMode: The desired presentation mode of the paywall. Defaults to `.sheet`.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    @available(iOS, deprecated: 1, renamed: "presentPaywallIfNeeded(offering:fonts:presentationMode:shouldDisplay:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(tvOS, deprecated: 1, renamed: "presentPaywallIfNeeded(offering:fonts:presentationMode:shouldDisplay:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(watchOS, deprecated: 1, renamed: "presentPaywallIfNeeded(offering:fonts:presentationMode:shouldDisplay:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(macOS, deprecated: 1, renamed: "presentPaywallIfNeeded(offering:fonts:presentationMode:shouldDisplay:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    @available(macCatalyst, deprecated: 1, renamed: "presentPaywallIfNeeded(offering:fonts:presentationMode:shouldDisplay:purchaseStarted:purchaseCompleted:purchaseCancelled:restoreStarted:restoreCompleted:purchaseFailure:restoreFailure:onDismiss:)")
    // swiftlint:enable line_length
    public func presentPaywallIfNeeded(
        offering: Offering? = nil,
        fonts: PaywallFontProvider = DefaultPaywallFontProvider(),
        presentationMode: PaywallPresentationMode = .default,
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseStarted: @escaping PurchaseStartedHandler,
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
            myAppPurchaseLogic: myAppPurchaseLogic,
            shouldDisplay: shouldDisplay,
            purchaseStarted: { _ in
                purchaseStarted()
            },
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: nil,
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

    /// Presents a ``PaywallView`` based a given condition.
    /// Example:
    /// ```swift
    /// var body: some View {
    ///    YourApp()
    ///      .presentPaywallIfNeeded {
    ///         !$0.entitlements.active.keys.contains("entitlement_identifier")
    ///     } purchaseStarted: { package in
    ///         print("Purchase started \(package)")
    ///     } purchaseCompleted: { customerInfo in
    ///         print("Customer info unlocked entitlement: \(customerInfo.entitlements)")
    ///     } purchaseCancelled: {
    ///         print("Purchase was cancelled")
    ///     } restoreStarted: {
    ///         print("Restore started")
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
    /// - Parameter offering: The `Offering` containing the desired paywall to display.
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
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        return self.presentPaywallIfNeeded(
            offering: offering,
            fonts: fonts,
            presentationMode: presentationMode,
            myAppPurchaseLogic: myAppPurchaseLogic,
            shouldDisplay: shouldDisplay,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
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
        myAppPurchaseLogic: MyAppPurchaseLogic? = nil,
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        purchaseStarted: PurchaseOfPackageStartedHandler? = nil,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseCancelled: PurchaseCancelledHandler? = nil,
        restoreStarted: RestoreStartedHandler? = nil,
        restoreCompleted: PurchaseOrRestoreCompletedHandler? = nil,
        purchaseFailure: PurchaseFailureHandler? = nil,
        restoreFailure: PurchaseFailureHandler? = nil,
        onDismiss: (() -> Void)? = nil,
        customerInfoFetcher: @escaping CustomerInfoFetcher
    ) -> some View {
        return self
            .modifier(PresentingPaywallModifier(
                shouldDisplay: shouldDisplay,
                myAppPurchaseLogic: myAppPurchaseLogic,
                presentationMode: presentationMode,
                purchaseStarted: purchaseStarted,
                purchaseCompleted: purchaseCompleted,
                purchaseCancelled: purchaseCancelled,
                restoreCompleted: restoreCompleted,
                purchaseFailure: purchaseFailure,
                restoreStarted: restoreStarted,
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
@available(tvOS, unavailable)
private struct PresentingPaywallModifier: ViewModifier {

    @Environment(\.scenePhase) var scenePhase

    private struct Data: Identifiable {
        var customerInfo: CustomerInfo
        var id: String { self.customerInfo.originalAppUserId }
    }

    var shouldDisplay: @Sendable (CustomerInfo) -> Bool
    var presentationMode: PaywallPresentationMode
    var purchaseStarted: PurchaseOfPackageStartedHandler?
    var purchaseCompleted: PurchaseOrRestoreCompletedHandler?
    var purchaseCancelled: PurchaseCancelledHandler?
    var restoreCompleted: PurchaseOrRestoreCompletedHandler?
    var purchaseFailure: PurchaseFailureHandler?
    var restoreStarted: RestoreStartedHandler?
    var restoreFailure: PurchaseFailureHandler?
    var onDismiss: (() -> Void)?

    var content: PaywallViewConfiguration.Content
    var fontProvider: PaywallFontProvider

    var customerInfoFetcher: View.CustomerInfoFetcher
    var introEligibility: TrialOrIntroEligibilityChecker?

    init(
        shouldDisplay: @escaping @Sendable (CustomerInfo) -> Bool,
        myAppPurchaseLogic: MyAppPurchaseLogic?,
        presentationMode: PaywallPresentationMode,
        purchaseStarted: PurchaseOfPackageStartedHandler?,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler?,
        purchaseCancelled: PurchaseCancelledHandler?,
        restoreCompleted: PurchaseOrRestoreCompletedHandler?,
        purchaseFailure: PurchaseFailureHandler?,
        restoreStarted: RestoreStartedHandler?,
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
        self.restoreStarted = restoreStarted
        self.restoreCompleted = restoreCompleted
        self.purchaseFailure = purchaseFailure
        self.restoreFailure = restoreFailure
        self.onDismiss = onDismiss
        self.content = content
        self.fontProvider = fontProvider
        self.customerInfoFetcher = customerInfoFetcher
        self.introEligibility = introEligibility
        self._purchaseHandler = .init(wrappedValue: purchaseHandler ??
                                      PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                                              performRestore: myAppPurchaseLogic?.performRestore))
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
                        // The default height given to sheets on Mac Catalyst is too small, and looks terrible.
                        // So we need to give it a more reasonable default size. This is the height of an
                        // iPhone 6/7/8 screen. This aligns with our documentation that we will show a paywall
                        // in a modal that is "roughly iPhone sized", and if you want to customize further you
                        // can use PaywallView.
                        // https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls
                        #if targetEnvironment(macCatalyst) || os(macOS)
                            .frame(height: 667)
                        #endif
                    }
            #if !os(macOS)
            case .fullScreen:
                content
                    .fullScreenCover(item: self.$data, onDismiss: self.onDismiss) { data in
                        self.paywallView(data)
                    }
            #endif
            }
        }
        .task {
            await self.updateCustomerInfo()
        }
        .onChangeOfWithChange(self.scenePhase) { value in
            // Used when Offer Code Redemption sheet dismisses
            switch value {
            case .new(let newPhase):
                if newPhase == .active {
                    Task {
                        await self.updateCustomerInfo()
                    }
                }
            case .changed(old: let oldPhase, new: let newPhase):
                // Used when Offer Code Redemption sheet dismisses
                if newPhase == .active && oldPhase == .inactive {
                    Task {
                        await self.updateCustomerInfo()
                    }
                }
            }
        }
    }

    private func updateCustomerInfo() async {
        guard let info = try? await self.customerInfoFetcher() else { return }

        Logger.debug(Strings.determining_whether_to_display_paywall)

        if self.shouldDisplay(info) {
            Logger.debug(Strings.displaying_paywall)

            self.data = .init(customerInfo: info)
        } else {
            Logger.debug(Strings.not_displaying_paywall)
            self.data = nil
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
            self.purchaseStarted?($0)
        }
        .onPurchaseCompleted {
            self.purchaseCompleted?($0)
        }
        .onPurchaseCancelled {
            self.purchaseCancelled?()
        }
        .onRestoreStarted {
            self.restoreStarted?()
        }
        .onRestoreCompleted { customerInfo in
            self.restoreCompleted?(customerInfo)
        }
        .onPreferenceChange(RestoredCustomerInfoPreferenceKey.self) { result in
            guard let result else { return }

            if result.success && !self.shouldDisplay(result.customerInfo) {
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
