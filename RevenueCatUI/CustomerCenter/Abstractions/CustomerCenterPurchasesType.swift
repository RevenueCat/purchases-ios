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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
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

    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer
    ) async throws -> PurchaseResultData

    func track(customerCenterEvent: any CustomerCenterEventType)

    func loadCustomerCenter() async throws -> CustomerCenterConfigData

    func restorePurchases() async throws -> CustomerInfo

    func syncPurchases() async throws -> CustomerInfo

    // MARK: - Subscription Management

    #if os(iOS) || os(visionOS)
    @Sendable
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus
    #endif

    @MainActor
    func manageSubscriptionsSheetViewModifier(isPresented: Binding<Bool>) -> ManageSubscriptionSheetModifier
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterPurchasesType {

    func manageSubscriptionsSheetViewModifier(isPresented: Binding<Bool>) -> ManageSubscriptionSheetModifier {
        ManageSubscriptionSheetModifier(isPresented: isPresented)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@_spi(Internal) public struct ManageSubscriptionSheetModifier: ViewModifier {

    let isPresented: Binding<Bool>

    @_spi(Internal) public init(isPresented: Binding<Bool>) {
        self.isPresented = isPresented
    }

    @_spi(Internal) public func body(content: Content) -> some View {
        content.manageSubscriptionsSheet(isPresented: isPresented)
    }
}
