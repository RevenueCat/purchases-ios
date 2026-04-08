//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PresentDynamicPaywall.swift

import RevenueCat
import SwiftUI

// swiftlint:disable file_length

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable, message: "RevenueCatUI does not support tvOS yet")
extension View {

    // MARK: - presentDynamicPaywallIfNeeded

    /// Presents a ``PaywallView`` with packages filtered by the given ``DynamicPaywallBehavior``.
    ///
    /// The modifier fetches `CustomerInfo`, resolves the offering, and applies the behavior's
    /// filter to determine which packages to show. If no packages survive the filter, the
    /// paywall is not presented.
    ///
    /// Example — show only upgrade options:
    /// ```swift
    /// var body: some View {
    ///     YourApp()
    ///         .presentDynamicPaywallIfNeeded(behavior: .upgrade)
    /// }
    /// ```
    ///
    /// With a placement-resolved offering:
    /// ```swift
    /// var body: some View {
    ///     YourApp()
    ///         .presentDynamicPaywallIfNeeded(
    ///             behavior: .upgrade,
    ///             offering: myPlacementOffering
    ///         )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - behavior: The ``DynamicPaywallBehavior`` that determines which packages to show.
    ///   - offering: The `Offering` to filter. If `nil`, `Offerings.current` is used.
    ///   - fonts: An optional ``PaywallFontProvider``.
    ///   - presentationMode: The desired presentation mode. Defaults to `.sheet`.
    ///   - purchaseStarted: Called when a purchase is initiated.
    ///   - purchaseCompleted: Called when a purchase completes successfully.
    ///   - purchaseCancelled: Called when a purchase is cancelled.
    ///   - restoreStarted: Called when a restore is initiated.
    ///   - restoreCompleted: Called when a restore completes successfully.
    ///   - purchaseFailure: Called when a purchase fails.
    ///   - restoreFailure: Called when a restore fails.
    ///   - onDismiss: Called when the paywall is dismissed.
    public func presentDynamicPaywallIfNeeded(
        behavior: DynamicPaywallBehavior,
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
        return self.modifier(PresentingDynamicPaywallModifier(
            behavior: behavior,
            content: .optionalOffering(offering),
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

    // MARK: - presentDynamicPaywall (Binding-based)

    /// Presents a ``PaywallView`` with packages filtered by the given ``DynamicPaywallBehavior``
    /// when the provided offering binding is non-nil.
    ///
    /// When the binding is set to a non-nil `Offering`, the behavior filter is applied.
    /// If no packages survive the filter, the binding is cleared and no paywall is shown.
    ///
    /// Example:
    /// ```swift
    /// @State private var offeringToPresent: Offering?
    ///
    /// var body: some View {
    ///     Button("Show Upgrade Options") {
    ///         offeringToPresent = myOffering
    ///     }
    ///     .presentDynamicPaywall(
    ///         behavior: .upgrade,
    ///         offering: $offeringToPresent
    ///     )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - behavior: The ``DynamicPaywallBehavior`` that determines which packages to show.
    ///   - offering: A binding to the offering to filter and display.
    ///   - fonts: An optional ``PaywallFontProvider``.
    ///   - presentationMode: The desired presentation mode. Defaults to `.sheet`.
    ///   - purchaseStarted: Called when a purchase is initiated.
    ///   - purchaseCompleted: Called when a purchase completes successfully.
    ///   - purchaseCancelled: Called when a purchase is cancelled.
    ///   - restoreStarted: Called when a restore is initiated.
    ///   - restoreCompleted: Called when a restore completes successfully.
    ///   - purchaseFailure: Called when a purchase fails.
    ///   - restoreFailure: Called when a restore fails.
    ///   - onDismiss: Called when the paywall is dismissed.
    public func presentDynamicPaywall(
        behavior: DynamicPaywallBehavior,
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
        return self.modifier(PresentingDynamicPaywallBindingModifier(
            behavior: behavior,
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

// MARK: - PresentingDynamicPaywallModifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
private struct PresentingDynamicPaywallModifier: ViewModifier {

    let behavior: DynamicPaywallBehavior
    let content: PaywallViewConfiguration.Content
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

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @StateObject
    private var promoOfferCache: PaywallPromoOfferCache

    @State
    private var filteredOffering: Offering?

    init(
        behavior: DynamicPaywallBehavior,
        content: PaywallViewConfiguration.Content,
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
        self.behavior = behavior
        self.content = content
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
        let handler = PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                              performRestore: myAppPurchaseLogic?.performRestore)
        self._purchaseHandler = .init(wrappedValue: handler)
        self._promoOfferCache = .init(wrappedValue: PaywallPromoOfferCache(
            subscriptionHistoryTracker: handler.subscriptionHistoryTracker
        ))
    }

    func body(content: Content) -> some View {
        Group {
            switch presentationMode {
            case .sheet:
                content
                    .sheet(item: self.$filteredOffering, onDismiss: self.handleDismiss) { offering in
                        self.paywallView(for: offering)
                        #if targetEnvironment(macCatalyst) || os(macOS)
                            .frame(height: 667)
                        #endif
                    }
            #if !os(macOS)
            case .fullScreen:
                content
                    .fullScreenCover(item: self.$filteredOffering, onDismiss: self.handleDismiss) { offering in
                        self.paywallView(for: offering)
                    }
            #endif
            }
        }
        .task {
            await self.resolveAndFilter()
        }
    }

    private func resolveAndFilter() async {
        guard Purchases.isConfigured else {
            Logger.warning(Strings.dynamicPaywall_purchasesNotConfigured)
            return
        }

        guard let offering = await self.content.resolveOffering() else {
            return
        }

        let customerInfo: CustomerInfo
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            Logger.warning(Strings.dynamicPaywall_purchasesNotConfigured)
            return
        }

        Logger.debug(Strings.determining_whether_to_display_paywall)

        if let filtered = await DynamicPaywallFilter.apply(
            behavior: self.behavior,
            to: offering,
            customerInfo: customerInfo
        ) {
            Logger.debug(Strings.displaying_paywall)
            self.filteredOffering = filtered
        } else {
            Logger.debug(Strings.not_displaying_paywall)
        }
    }

    private func paywallView(for offering: Offering) -> some View {
        PaywallView(
            configuration: .init(
                content: .offering(offering),
                fonts: self.fontProvider,
                displayCloseButton: true,
                purchaseHandler: self.purchaseHandler,
                promoOfferCache: self.promoOfferCache
            )
        )
        .onPurchaseStarted {
            self.purchaseStarted?($0)
        }
        .onPurchaseCompleted { customerInfo in
            self.purchaseCompleted?(customerInfo)
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
            guard let result, result.success else { return }
            self.close()
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
        self.filteredOffering = nil
    }

    private func handleDismiss() {
        self.purchaseHandler.trackPaywallClose()
        self.purchaseHandler.resetForNewSession()
        self.onDismiss?()
    }

}

// MARK: - PresentingDynamicPaywallBindingModifier

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
private struct PresentingDynamicPaywallBindingModifier: ViewModifier {

    let behavior: DynamicPaywallBehavior
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

    @State
    private var filteredOffering: Offering?

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @StateObject
    private var promoOfferCache: PaywallPromoOfferCache

    init(
        behavior: DynamicPaywallBehavior,
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
        self.behavior = behavior
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
        let handler = PurchaseHandler.default(performPurchase: myAppPurchaseLogic?.performPurchase,
                                              performRestore: myAppPurchaseLogic?.performRestore)
        self._purchaseHandler = .init(wrappedValue: handler)
        self._promoOfferCache = .init(wrappedValue: PaywallPromoOfferCache(
            subscriptionHistoryTracker: handler.subscriptionHistoryTracker
        ))
    }

    func body(content: Content) -> some View {
        Group {
            switch presentationMode {
            case .sheet:
                content
                    .sheet(item: self.$filteredOffering, onDismiss: self.handleDismiss) { offering in
                        self.paywallView(for: offering)
                        #if targetEnvironment(macCatalyst) || os(macOS)
                            .frame(minHeight: 667)
                        #endif
                    }
            #if !os(macOS)
            case .fullScreen:
                content
                    .fullScreenCover(item: self.$filteredOffering, onDismiss: self.handleDismiss) { offering in
                        self.paywallView(for: offering)
                    }
            #endif
            }
        }
        .onChange(of: self.offering?.id) { offeringID in
            guard offeringID != nil, let sourceOffering = self.offering else {
                self.filteredOffering = nil
                return
            }
            Task {
                await self.applyFilter(to: sourceOffering)
            }
        }
    }

    private func applyFilter(to offering: Offering) async {
        guard Purchases.isConfigured else {
            Logger.warning(Strings.dynamicPaywall_purchasesNotConfigured)
            self.offering = nil
            return
        }

        let customerInfo: CustomerInfo
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            Logger.warning(Strings.dynamicPaywall_purchasesNotConfigured)
            self.offering = nil
            return
        }

        if let filtered = await DynamicPaywallFilter.apply(
            behavior: self.behavior,
            to: offering,
            customerInfo: customerInfo
        ) {
            Logger.debug(Strings.displaying_paywall)
            self.filteredOffering = filtered
        } else {
            Logger.debug(Strings.not_displaying_paywall)
            self.offering = nil
        }
    }

    private func paywallView(for offering: Offering) -> some View {
        PaywallView(
            configuration: .init(
                content: .offering(offering),
                fonts: self.fontProvider,
                displayCloseButton: true,
                purchaseHandler: self.purchaseHandler,
                promoOfferCache: self.promoOfferCache
            )
        )
        .onPurchaseStarted {
            self.purchaseStarted?($0)
        }
        .onPurchaseCompleted { customerInfo in
            self.purchaseCompleted?(customerInfo)
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
            guard let result, result.success else { return }
            self.close()
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
        self.filteredOffering = nil
        self.offering = nil
    }

    private func handleDismiss() {
        self.filteredOffering = nil
        self.offering = nil
        self.purchaseHandler.trackPaywallClose()
        self.purchaseHandler.resetForNewSession()
        self.onDismiss?()
    }

}

#endif

// swiftlint:enable file_length
