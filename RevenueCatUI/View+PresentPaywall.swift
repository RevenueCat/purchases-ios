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

    // MARK: - Present Paywall (Binding-based)

    /// Presents a ``PaywallView`` when the provided offering binding is non-nil.
    ///
    /// This modifier is designed for on-demand paywall presentation, where you control
    /// when the paywall appears by setting the offering binding.
    ///
    /// Example:
    /// ```swift
    /// @State private var offeringToPresent: Offering?
    ///
    /// var body: some View {
    ///     Button("Show Paywall") {
    ///         offeringToPresent = myOffering
    ///     }
    ///     .presentPaywall(
    ///         offering: $offeringToPresent,
    ///         onDismiss: {
    ///             print("Paywall dismissed")
    ///         }
    ///     )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - offering: A binding to the offering to display. When non-nil, the paywall is presented.
    ///     The binding is set to `nil` when the paywall (and any exit offer) is dismissed.
    ///   - fonts: An optional ``PaywallFontProvider``.
    ///   - presentationMode: The desired presentation mode of the paywall. Defaults to `.sheet`.
    ///   - purchaseStarted: Called when a purchase is initiated.
    ///   - purchaseCompleted: Called when a purchase completes successfully.
    ///   - purchaseCancelled: Called when a purchase is cancelled.
    ///   - restoreStarted: Called when a restore is initiated.
    ///   - restoreCompleted: Called when a restore completes successfully.
    ///   - purchaseFailure: Called when a purchase fails.
    ///   - restoreFailure: Called when a restore fails.
    ///   - onDismiss: Called when the paywall (and any exit offer) is fully dismissed.
    ///
    /// ### Related Articles
    /// [Documentation](https://rev.cat/paywalls)
    public func presentPaywall(
        offering: Binding<Offering?>,
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
        return self.modifier(PresentingPaywallBindingModifier(
            offering: offering,
            myAppPurchaseLogic: myAppPurchaseLogic,
            presentationMode: presentationMode,
            fontProvider: fonts,
            purchaseStarted: purchaseStarted,
            purchaseCompleted: purchaseCompleted,
            purchaseCancelled: purchaseCancelled,
            restoreStarted: restoreStarted,
            restoreCompleted: restoreCompleted,
            purchaseFailure: purchaseFailure,
            restoreFailure: restoreFailure,
            onDismiss: onDismiss
        ))
    }

}

// swiftlint:disable type_body_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
private struct PresentingPaywallModifier: ViewModifier {

    @Environment(\.scenePhase) var scenePhase
    @Environment(\.customPaywallVariables) private var customPaywallVariables

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

    /// The prefetched exit offer, loaded while the main paywall is showing.
    /// This enables immediate presentation when the main paywall dismisses (no loading delay).
    /// Copied to `presentedExitOffer` when ready to show.
    @State
    private var exitOfferOffering: Offering?

    /// The exit offer currently being presented. Controls the sheet/fullScreenCover.
    /// Set from `exitOfferOffering` when the main paywall dismisses without a purchase.
    @State
    private var presentedExitOffer: Offering?

    func body(content: Content) -> some View {
        Group {
            switch presentationMode {
            case .sheet:
                content
                    .sheet(item: self.$data, onDismiss: self.handleMainPaywallDismiss) { data in
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
                    .sheet(item: self.$presentedExitOffer, onDismiss: self.handleExitOfferDismiss) { offering in
                        self.exitOfferPaywallView(for: offering)
                        #if targetEnvironment(macCatalyst) || os(macOS)
                        // this should be minHeight, but for consistency with the first paywall it will be
                        // like this for now
                            .frame(height: 667)
                        #endif
                    }
            #if !os(macOS)
            case .fullScreen:
                content
                    .fullScreenCover(item: self.$data, onDismiss: self.handleMainPaywallDismiss) { data in
                        self.paywallView(data)
                    }
                    .fullScreenCover(
                        item: self.$presentedExitOffer,
                        onDismiss: self.handleExitOfferDismiss
                    ) { offering in
                        self.exitOfferPaywallView(for: offering)
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
        .onPurchaseCompleted { customerInfo in
            self.purchaseCompleted?(customerInfo)
            // Always close on successful purchase - shouldDisplay drives when to show, not when to close
            self.close()
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

            // For restore, check shouldDisplay since restore might succeed without granting the expected entitlement
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
        .task {
            guard let offering = await self.content.resolveOffering() else { return }
            self.exitOfferOffering = await ExitOfferHelper.fetchValidExitOffer(for: offering)
        }
    }

    private func close() {
        Logger.debug(Strings.dismissing_paywall)

        self.data = nil
    }

    private func closeExitOffer() {
        Logger.debug(Strings.dismissing_paywall)

        self.presentedExitOffer = nil
        self.exitOfferOffering = nil
    }

    /// Handles dismissal of the main paywall, checking for exit offers.
    ///
    /// We check `purchaseHandler.sessionPurchaseResult` to determine if exit offer should be shown:
    /// - If a purchase happened in this session, we use `shouldDisplay` with the result's `CustomerInfo`
    /// - This ensures consistent behavior with how the first paywall decides to show/close
    private func handleMainPaywallDismiss() {
        // Prevent double processing
        guard self.presentedExitOffer == nil else { return }

        guard !purchaseHandler.hasPurchasedInSession else {
            self.purchaseHandler.trackPaywallClose()
            self.purchaseHandler.resetForNewSession()
            self.onDismiss?()
            return
        }

        // Check shouldDisplay with the purchase result if available
        if let purchaseResult = self.purchaseHandler.sessionPurchaseResult,
           !purchaseResult.userCancelled,
           !self.shouldDisplay(purchaseResult.customerInfo) {
            self.purchaseHandler.trackPaywallClose()
            self.purchaseHandler.resetForNewSession()
            self.onDismiss?()
            return
        }

        self.purchaseHandler.trackPaywallClose()

        if let exitOffering = self.exitOfferOffering {
            Logger.debug(Strings.presentingExitOffer(exitOffering.identifier))
            self.purchaseHandler.trackExitOffer(
                exitOfferType: .dismiss,
                exitOfferingIdentifier: exitOffering.identifier
            )
            self.presentedExitOffer = exitOffering
        } else {
            self.purchaseHandler.resetForNewSession()
            self.onDismiss?()
        }
    }

    private func handleExitOfferDismiss() {
        self.presentedExitOffer = nil
        self.exitOfferOffering = nil
        self.purchaseHandler.resetForNewSession()
        self.onDismiss?()
    }

    private func exitOfferPaywallView(for offering: Offering) -> some View {
        PaywallView(
            configuration: .init(
                content: .offering(offering),
                fonts: self.fontProvider,
                displayCloseButton: true,
                introEligibility: self.introEligibility,
                purchaseHandler: self.purchaseHandler
            )
        )
        .customPaywallVariables(self.customPaywallVariables)
        .onPurchaseStarted {
            self.purchaseStarted?($0)
        }
        .onPurchaseCompleted { customerInfo in
            self.purchaseCompleted?(customerInfo)
            // Always close on successful purchase - shouldDisplay drives when to show, not when to close
            self.closeExitOffer()
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

            // For restore, check shouldDisplay since restore might succeed without granting the expected entitlement
            if result.success && !self.shouldDisplay(result.customerInfo) {
                self.closeExitOffer()
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

}
// swiftlint:enable type_body_length

// MARK: - PresentingPaywallBindingModifier

/// A ViewModifier that presents a paywall based on a binding to an Offering.
/// Supports exit offers on dismissal.
///
/// Unlike `PresentingPaywallModifier`, this modifier does not have a `shouldDisplay` function.
/// The caller controls presentation via the binding and is responsible for dismissing when appropriate.
/// If `shouldDisplay` logic were added, it would be used:
/// 1. Before presenting the exit offer (skip if user already has entitlement)
/// 2. After restore in both paywalls (dismiss if entitlement was granted)
/// 3. After purchase in both paywalls (dismiss if entitlement was granted)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
private struct PresentingPaywallBindingModifier: ViewModifier {

    @Environment(\.customPaywallVariables) private var customPaywallVariables

    @Binding var offering: Offering?

    var presentationMode: PaywallPresentationMode
    var fontProvider: PaywallFontProvider

    var purchaseStarted: PurchaseOfPackageStartedHandler?
    var purchaseCompleted: PurchaseOrRestoreCompletedHandler?
    var purchaseCancelled: PurchaseCancelledHandler?
    var restoreStarted: RestoreStartedHandler?
    var restoreCompleted: PurchaseOrRestoreCompletedHandler?
    var purchaseFailure: PurchaseFailureHandler?
    var restoreFailure: PurchaseFailureHandler?
    var onDismiss: (() -> Void)?

    /// The prefetched exit offer, loaded while the main paywall is showing.
    /// This enables immediate presentation when the main paywall dismisses (no loading delay).
    /// Copied to `presentedExitOffer` when ready to show.
    @State
    private var exitOfferOffering: Offering?

    /// The exit offer currently being presented. Controls the sheet/fullScreenCover.
    /// Set from `exitOfferOffering` when the main paywall dismisses without a purchase.
    @State
    private var presentedExitOffer: Offering?

    @StateObject
    private var purchaseHandler: PurchaseHandler

    init(
        offering: Binding<Offering?>,
        myAppPurchaseLogic: MyAppPurchaseLogic?,
        presentationMode: PaywallPresentationMode,
        fontProvider: PaywallFontProvider,
        purchaseStarted: PurchaseOfPackageStartedHandler?,
        purchaseCompleted: PurchaseOrRestoreCompletedHandler?,
        purchaseCancelled: PurchaseCancelledHandler?,
        restoreStarted: RestoreStartedHandler?,
        restoreCompleted: PurchaseOrRestoreCompletedHandler?,
        purchaseFailure: PurchaseFailureHandler?,
        restoreFailure: PurchaseFailureHandler?,
        onDismiss: (() -> Void)?
    ) {
        self._offering = offering
        self.presentationMode = presentationMode
        self.fontProvider = fontProvider
        self.purchaseStarted = purchaseStarted
        self.purchaseCompleted = purchaseCompleted
        self.purchaseCancelled = purchaseCancelled
        self.restoreStarted = restoreStarted
        self.restoreCompleted = restoreCompleted
        self.purchaseFailure = purchaseFailure
        self.restoreFailure = restoreFailure
        self.onDismiss = onDismiss
        self._purchaseHandler = .init(wrappedValue:
            PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                    performRestore: myAppPurchaseLogic?.performRestore))
    }

    func body(content: Content) -> some View {
        Group {
            switch presentationMode {
            case .sheet:
                content
                    .sheet(item: self.$offering, onDismiss: self.handleMainPaywallDismiss) { offering in
                        self.paywallView(for: offering)
                        #if targetEnvironment(macCatalyst) || os(macOS)
                            .frame(minHeight: 667)
                        #endif
                    }
                    .sheet(item: self.$presentedExitOffer, onDismiss: self.handleExitOfferDismiss) { exitOffering in
                        self.exitOfferPaywallView(for: exitOffering)
                        #if targetEnvironment(macCatalyst) || os(macOS)
                            .frame(minHeight: 667)
                        #endif
                    }
            #if !os(macOS)
            case .fullScreen:
                content
                    .fullScreenCover(item: self.$offering, onDismiss: self.handleMainPaywallDismiss) { offering in
                        self.paywallView(for: offering)
                    }
                    .fullScreenCover(
                        item: self.$presentedExitOffer,
                        onDismiss: self.handleExitOfferDismiss
                    ) { exitOffering in
                        self.exitOfferPaywallView(for: exitOffering)
                    }
            #endif
            }
        }
    }

    private func paywallView(for offering: Offering) -> some View {
        PaywallView(
            configuration: .init(
                content: .offering(offering),
                fonts: self.fontProvider,
                displayCloseButton: true,
                purchaseHandler: self.purchaseHandler
            )
        )
        .onPurchaseStarted {
            self.purchaseStarted?($0)
        }
        .onPurchaseCompleted { customerInfo in
            self.purchaseCompleted?(customerInfo)
            // Always close on successful purchase
            self.offering = nil
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
            guard let result, result.success else { return }
            // Close on successful restore
            self.offering = nil
        }
        .onPurchaseFailure {
            self.purchaseFailure?($0)
        }
        .onRestoreFailure {
            self.restoreFailure?($0)
        }
        .interactiveDismissDisabled(self.purchaseHandler.actionInProgress)
        .task {
            self.exitOfferOffering = await ExitOfferHelper.fetchValidExitOffer(for: offering)
        }
    }

    private func exitOfferPaywallView(for offering: Offering) -> some View {
        PaywallView(
            configuration: .init(
                content: .offering(offering),
                fonts: self.fontProvider,
                displayCloseButton: true,
                purchaseHandler: self.purchaseHandler
            )
        )
        .customPaywallVariables(self.customPaywallVariables)
        .onPurchaseStarted {
            self.purchaseStarted?($0)
        }
        .onPurchaseCompleted { customerInfo in
            self.purchaseCompleted?(customerInfo)
            // Always close on successful purchase
            self.presentedExitOffer = nil
            self.exitOfferOffering = nil
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
            guard let result, result.success else { return }
            // Close on successful restore
            self.presentedExitOffer = nil
            self.exitOfferOffering = nil
        }
        .onPurchaseFailure {
            self.purchaseFailure?($0)
        }
        .onRestoreFailure {
            self.restoreFailure?($0)
        }
        .interactiveDismissDisabled(self.purchaseHandler.actionInProgress)
    }

    /// Handles dismissal of the main paywall, checking for exit offers.
    ///
    /// We check `purchaseHandler.hasPurchasedInSession` instead of fetching `CustomerInfo` because:
    /// - `sessionPurchaseResult` is set immediately when purchase completes, with no timing issues
    /// - Fetching `CustomerInfo` may return cached data that hasn't been updated yet
    private func handleMainPaywallDismiss() {
        // Prevent double processing
        guard self.presentedExitOffer == nil else { return }

        guard !self.purchaseHandler.hasPurchasedInSession else {
            self.purchaseHandler.trackPaywallClose()
            self.purchaseHandler.resetForNewSession()
            self.onDismiss?()
            return
        }

        // Don't show exit offer if main paywall is still showing
        guard self.offering == nil else {
            self.onDismiss?()
            return
        }

        self.purchaseHandler.trackPaywallClose()

        if let exitOffering = self.exitOfferOffering {
            Logger.debug(Strings.presentingExitOffer(exitOffering.identifier))
            self.purchaseHandler.trackExitOffer(
                exitOfferType: .dismiss,
                exitOfferingIdentifier: exitOffering.identifier
            )
            self.presentedExitOffer = exitOffering
        } else {
            self.purchaseHandler.resetForNewSession()
            self.onDismiss?()
        }
    }

    private func handleExitOfferDismiss() {
        self.presentedExitOffer = nil
        self.exitOfferOffering = nil
        self.purchaseHandler.resetForNewSession()
        self.onDismiss?()
    }

}

#endif
