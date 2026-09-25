//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterPurchaseType.swift
//
//  Created by Cesar de la Vega on 18/7/24.

import Foundation
@_spi(Internal) import RevenueCat
import StoreKit
import SwiftUI

// swiftlint:disable missing_docs

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@_spi(Internal) public protocol CustomerCenterPurchasesType: Sendable {

    var isSandbox: Bool { get }
    var appUserID: String { get }
    var isConfigured: Bool { get }
    var storeFrontCountryCode: String? { get }

    @Sendable
    func customerInfo() async throws -> CustomerInfo

    @Sendable
    func customerInfo(
        fetchPolicy: CacheFetchPolicy
    ) async throws -> CustomerInfo

    @Sendable
    func products(_ productIdentifiers: [String]) async -> [StoreProduct]

    func promotionalOffer(forProductDiscount discount: StoreProductDiscount,
                          product: StoreProduct) async throws -> PromotionalOffer

/// Initiates a purchase.
///
/// This method is used in two main contexts:
/// - **PromotionalOfferViewModel**: To handle promotional offers that a customer is
///   eligible for.
/// - **NoSubscriptionCardView**: To serve purchases directly through your paywall UI.
///
/// If a `PromotionalOffer` is provided, the system will attempt to apply it.
/// Otherwise, a standard purchase flow is executed.
///
/// - Parameters:
///   - product: The `StoreProduct` the customer intends to purchase.
///   - promotionalOffer: An optional `PromotionalOffer` to apply
/// - Returns: A `PurchaseResultData` object containing the result of the purchase.
/// - Throws: An error if the purchase flow fails or is cancelled.
    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer?
    ) async throws -> PurchaseResultData

    func purchase(package: Package) async throws -> PurchaseResultData

    func track(customerCenterEvent: any CustomerCenterEventType)

    func loadCustomerCenter() async throws -> CustomerCenterConfigData

    func restorePurchases() async throws -> CustomerInfo

    func syncPurchases() async throws -> CustomerInfo

    func invalidateVirtualCurrenciesCache()

    func virtualCurrencies() async throws -> RevenueCat.VirtualCurrencies

    func offerings() async throws -> RevenueCat.Offerings

    @Sendable
    func createTicket(customerEmail: String, ticketDescription: String) async throws -> Bool

    // MARK: - Subscription Management

    #if os(iOS) || os(macOS) || os(visionOS)
    /// Opens the platform's subscription management surface: StoreKit's manage-subscriptions
    /// sheet on iOS, or the App Store's subscriptions page (via `NSWorkspace`) on macOS, where
    /// no such sheet exists. Mirrors the availability of `Purchases.showManageSubscriptions()`
    /// in the core SDK, which this requirement forwards to.
    @Sendable
    func showManageSubscriptions() async throws
    #endif

    #if os(iOS) || os(visionOS)
    @Sendable
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus
    #endif

    @MainActor
    func manageSubscriptionsSheetViewModifier(
        isPresented: Binding<Bool>,
        subscriptionGroupID: String?
    ) -> ManageSubscriptionSheetModifier
}

#if os(iOS) || os(macOS) || os(visionOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterPurchasesType {

    /// Default forwards to the configured `Purchases`. `@_spi(Internal) public` so conformers
    /// outside this module keep compiling without implementing the requirement; a conformer
    /// used without a configured `Purchases` (a preview provider, say) gets a warning instead of
    /// `Purchases.shared`'s fatal error.
    @_spi(Internal) public func showManageSubscriptions() async throws {
        guard Purchases.isConfigured else {
            Logger.warning(Strings.could_not_show_manage_subscriptions_purchases_not_configured)
            return
        }
        try await Purchases.shared.showManageSubscriptions()
    }

}

#endif

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterPurchasesType {

    func manageSubscriptionsSheetViewModifier(
        isPresented: Binding<Bool>,
        subscriptionGroupID: String?
    ) -> ManageSubscriptionSheetModifier {
        ManageSubscriptionSheetModifier(isPresented: isPresented, subscriptionGroupID: subscriptionGroupID)
    }
}

@available(iOS 15.0, macOS 13.0, tvOS 17.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterPurchasesType {

    func changePlansSheetViewModifier(
        isPresented: Binding<Bool>,
        subscriptionGroupID: String?,
        productIDs: [String]
    ) -> ChangePlansSheetViewModifier {
        ChangePlansSheetViewModifier(
            isPresented: isPresented,
            subscriptionGroupID: subscriptionGroupID,
            productIDs: productIDs
        )
    }
}

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@_spi(Internal) public struct ChangePlansSheetViewModifier: ViewModifier {

    let isPresented: Binding<Bool>
    let subscriptionGroupID: String?
    let productIDs: [String]

    @_spi(Internal) public init(
        isPresented: Binding<Bool>,
        subscriptionGroupID: String?,
        productIDs: [String]
    ) {
        self.isPresented = isPresented
        self.subscriptionGroupID = subscriptionGroupID
        self.productIDs = productIDs
    }

    /// Whether `SubscriptionStoreView` has something to show for these inputs: at least two
    /// products to switch between, or a subscription group. Without either, iOS falls back to
    /// StoreKit's manage-subscriptions sheet, which macOS does not have, so on macOS the view model
    /// opens the App Store's subscriptions page instead of raising this sheet.
    static func presentsStoreView(subscriptionGroupID: String?, productIDs: [String]) -> Bool {
        productIDs.count >= 2 || subscriptionGroupID != nil
    }

    @_spi(Internal) public func body(content: Content) -> some View {
        #if swift(>=5.9)
        let validAmountOfProducts = productIDs.count >= 2
        if #available(iOS 17.0, macOS 14.0, tvOS 17, watchOS 10.0, *),
           Self.presentsStoreView(subscriptionGroupID: subscriptionGroupID, productIDs: productIDs) {
            content
                .sheet(isPresented: isPresented) {
                    Group {
                        if validAmountOfProducts {
                            SubscriptionStoreView(
                                productIDs: productIDs
                            )
                        } else if let subscriptionGroupID {
                            SubscriptionStoreView(
                                groupID: subscriptionGroupID
                            )
                        }
                    }
                    #if os(macOS)
                    // Sized like every other Customer Center sheet on the Mac: left to its ideal
                    // size, StoreKit's loading and error states open as a strip.
                    .customerCenterSheetFrame()
                    #endif
                }
        } else {
            #if !os(macOS)
            content.manageSubscriptionsSheet(isPresented: isPresented)
            #else
            // macOS has no manage-subscriptions sheet. The view model never raises this sheet
            // when `presentsStoreView` is false there (it opens the App Store page instead), and
            // below macOS 14.0 the change-plans path is not offered at all.
            content
            #endif
        }
        #else
        #if !os(macOS)
        content.manageSubscriptionsSheet(isPresented: isPresented)
        #else
        content
        #endif
        #endif
    }
}

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@_spi(Internal) public struct ManageSubscriptionSheetModifier: ViewModifier {

    let isPresented: Binding<Bool>
    let subscriptionGroupID: String?

    @_spi(Internal) public init(isPresented: Binding<Bool>, subscriptionGroupID: String?) {
        self.isPresented = isPresented
        self.subscriptionGroupID = subscriptionGroupID
    }

    @_spi(Internal) public func body(content: Content) -> some View {
        #if !os(macOS)
        #if swift(>=5.9)
        if #available(iOS 17.0, *), let subscriptionGroupID {
            content.manageSubscriptionsSheet(isPresented: isPresented, subscriptionGroupID: subscriptionGroupID)
        } else {
            content.manageSubscriptionsSheet(isPresented: isPresented)
        }
        #else
        content.manageSubscriptionsSheet(isPresented: isPresented)
        #endif
        #else
        // manageSubscriptionsSheet does not exist on macOS: there the view model opens the App
        // Store's subscriptions page and lowers the flag when the app becomes active again.
        content
        #endif
    }
}
