//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHandler.swift
//  
//  Created by Nacho Soto on 7/13/23.

import RevenueCat
import StoreKit
import SwiftUI

// swiftlint:disable file_length

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
final class PurchaseHandler: ObservableObject {

    private let purchases: PaywallPurchasesType

    /// Where responsibiliy for completing purchases lies
    var purchasesAreCompletedBy: PurchasesAreCompletedBy {
        purchases.purchasesAreCompletedBy
    }

    /// `false` if this `PurchaseHandler` is not backend by a configured `Purchases`instance.
    let isConfigured: Bool

    /// Whether a purchase is currently in progress
    @Published
    fileprivate(set) var packageBeingPurchased: Package?

    /// Whether a purchase or restore is currently in progress
    @Published
    fileprivate(set) var actionInProgress: Bool = false

    /// Whether a purchase was successfully completed.
    @Published
    fileprivate(set) var purchased: Bool = false

    /// When `purchased` becomes `true`, this will include the `CustomerInfo` 
    /// associated to it IF RevenueCat is making the purchase.
    @Published
    fileprivate(set) var purchaseResult: PurchaseResultData?

    /// When `purchasesAreCompletedBy` is `.myApp`, this is the app-defined
    /// callback method that performs the purchase
    @Published
    private(set) var performPurchase: PerformPurchase?

    /// When `purchasesAreCompletedBy` is `.myApp`, this is the app-defined
    /// callback method that performs the restore
    @Published
    private(set) var performRestore: PerformRestore?

    /// Whether a restore is currently in progress
    @Published
    fileprivate(set) var restoreInProgress: Bool = false

    /// Set manually by `setRestored(:_)` once the user is notified that restoring was successful..
    @Published
    fileprivate(set) var restoredCustomerInfo: CustomerInfo?

    /// Error produced during a purchase.
    @Published
    fileprivate(set) var purchaseError: Error?

    /// Error produced during restoring..
    @Published
    fileprivate(set) var restoreError: Error?

    private var eventData: PaywallEvent.Data?

    // @PublicForExternalTesting
    convenience init(purchases: Purchases = .shared,
                     performPurchase: PerformPurchase? = nil,
                     performRestore: PerformRestore? = nil) {
        self.init(isConfigured: true,
                  purchases: purchases,
                  performPurchase: performPurchase,
                  performRestore: performRestore)
    }

    init(
        isConfigured: Bool = true,
        purchases: PaywallPurchasesType,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil
    ) {
        self.isConfigured = isConfigured
        self.purchases = purchases
        self.performPurchase = performPurchase
        self.performRestore = performRestore
    }

    /// Returns a new instance of `PurchaseHandler` using `Purchases.shared` if `Purchases`
    /// has been configured, and using a PurchaseHandler that cannot be used for purchases otherwise.
    // @PublicForExternalTesting
    static func `default`(performPurchase: PerformPurchase? = nil,
                          performRestore: PerformRestore? = nil) -> Self {
        return Purchases.isConfigured ? .init(performPurchase: performPurchase,
                                              performRestore: performRestore) :
                                        Self.notConfigured(performPurchase: performPurchase,
                                                           performRestore: performRestore)
    }

    // @PublicForExternalTesting
    static func `default`(performPurchase: PerformPurchase? = nil,
                          performRestore: PerformRestore? = nil,
                          customerInfo: CustomerInfo,
                          purchasesAreCompletedBy: PurchasesAreCompletedBy) -> Self {
        return Purchases.isConfigured ? .init(performPurchase: performPurchase,
                                              performRestore: performRestore) :
                                        Self.notConfigured(performPurchase: performPurchase,
                                                           performRestore: performRestore,
                                                           customerInfo: customerInfo,
                                                           purchasesAreCompletedBy: purchasesAreCompletedBy)
    }

    private static func notConfigured(performPurchase: PerformPurchase?,
                                      performRestore: PerformRestore?,
                                      customerInfo: CustomerInfo? = nil,
                                      purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat) -> Self {
        return .init(isConfigured: false,
                     purchases: NotConfiguredPurchases(customerInfo: customerInfo,
                                                       purchasesAreCompletedBy: purchasesAreCompletedBy),
                                                       performPurchase: performPurchase,
                                                       performRestore: performRestore)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    // MARK: - Purchase

    @MainActor
    func purchase(package: Package) async throws {
        switch self.purchases.purchasesAreCompletedBy {
        case .revenueCat:
            try await performPurchase(package: package)
        case .myApp:
            try await performExternalPurchaseLogic(package: package)
        }
    }

    @MainActor
    func performPurchase(package: Package) async throws {
        Logger.debug(Strings.executing_purchase_logic)
        self.packageBeingPurchased = package
        self.purchaseResult = nil
        self.purchaseError = nil

        defer {
            self.packageBeingPurchased = nil
            self.actionInProgress = false
        }

        self.startAction()

        do {
            let result = try await self.purchases.purchase(package: package)
            self.purchaseResult = result

            if result.userCancelled {
                self.trackCancelledPurchase()
            } else {
                withAnimation(Constants.defaultAnimation) {
                    self.purchased = true
                }
            }

        } catch {
            self.purchaseError = error
            throw error
        }
    }

    @MainActor
    func performExternalPurchaseLogic(package: Package) async throws {
        Logger.debug(Strings.executing_external_purchase_logic)

        guard let externalPurchaseMethod = self.performPurchase else {
            throw PaywallError.performPurchaseAndRestoreHandlersNotDefined(missingBlocks: "performPurchase is")
        }

        self.packageBeingPurchased = package
        self.purchaseResult = nil
        self.purchaseError = nil

        defer {
            self.restoreInProgress = false
            self.actionInProgress = false
        }

        self.startAction()

        let result = await externalPurchaseMethod(package)

        if result.userCancelled {
            self.trackCancelledPurchase()
        }

        if let error = result.error {
            self.purchaseError = error
            throw error
        }

        let resultInfo: PurchaseResultData = (transaction: nil,
                                             customerInfo: try await self.purchases.customerInfo(),
                                            userCancelled: result.userCancelled)

        self.purchaseResult = resultInfo

        if !result.userCancelled && result.error == nil {

            withAnimation(Constants.defaultAnimation) {
                self.purchased = true
            }
        }

    }

    // MARK: - Restore

    func restorePurchases() async throws -> (info: CustomerInfo, success: Bool) {
        switch self.purchases.purchasesAreCompletedBy {
        case .revenueCat:
            return try await performRestorePurchases()
        case .myApp:
            return try await performExternalRestoreLogic()
        }
    }

    /// - Returns: `success` is `true` only when the resulting `CustomerInfo`
    /// had any transactions
    /// - Note: `restoredCustomerInfo` will be not be set after this method,
    /// instead `setRestored(_:)` must be manually called afterwards.
    /// This allows the UI to display an alert before dismissing the paywall.
    @MainActor
    func performRestorePurchases() async throws -> (info: CustomerInfo, success: Bool) {
        Logger.debug(Strings.executing_restore_logic)
        self.restoreInProgress = true
        self.restoredCustomerInfo = nil
        self.restoreError = nil

        self.startAction()
        defer {
            self.restoreInProgress = false
            self.actionInProgress = false
        }

        do {
            let customerInfo = try await self.purchases.restorePurchases()

            return (info: customerInfo,
                    success: customerInfo.hasActiveSubscriptionsOrNonSubscriptions)
        } catch {
            self.restoreError = error
            throw error
        }
    }

    @MainActor
    func performExternalRestoreLogic() async throws -> (info: CustomerInfo, success: Bool) {
        Logger.debug(Strings.executing_external_restore_logic)

        guard let externalRestoreMethod = self.performRestore else {
            throw PaywallError.performPurchaseAndRestoreHandlersNotDefined(missingBlocks: "performRestore is")
        }

        defer {
            self.restoreInProgress = false
            self.actionInProgress = false
        }

        self.restoreInProgress = true
        self.restoredCustomerInfo = nil
        self.restoreError = nil

        self.startAction()

        let result = await externalRestoreMethod()

        if let error = result.error {
            self.restoreError = error
            throw error
        }

        let customerInfo = try await self.purchases.customerInfo()

        // This is done by `RestorePurchasesButton` when using RevenueCat logic.
        self.setRestored(customerInfo)

        return (info: customerInfo, result.success)
    }

    @MainActor
    func setRestored(_ customerInfo: CustomerInfo) {
        self.restoredCustomerInfo = customerInfo
    }

    func trackPaywallImpression(_ eventData: PaywallEvent.Data) {
        self.eventData = eventData
        self.track(.impression(.init(), eventData))
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose() -> Bool {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        self.track(.close(.init(), data))
        self.eventData = nil
        return true
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    fileprivate func trackCancelledPurchase() -> Bool {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        self.track(.cancel(.init(), data))
        return true
    }

    private func startAction() {
        withAnimation(Constants.fastAnimation) {
            self.actionInProgress = true
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    /// Creates a copy of this `PurchaseHandler` wrapping the purchase and restore blocks.
    func map(
        purchase: @escaping (@escaping MockPurchases.PurchaseBlock) -> MockPurchases.PurchaseBlock,
        restore: @escaping (@escaping MockPurchases.RestoreBlock) -> MockPurchases.RestoreBlock
    ) -> Self {
        return .init(
            isConfigured: self.isConfigured,
            purchases: self.purchases.map(purchase: purchase, restore: restore)
        )
    }

    func map(
        trackEvent: @escaping (@escaping MockPurchases.TrackEventBlock) -> MockPurchases.TrackEventBlock
    ) -> Self {
        return .init(
            isConfigured: self.isConfigured,
            purchases: self.purchases.map(trackEvent: trackEvent)
        )
    }

}

#endif

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PurchaseHandler {

    func track(_ event: PaywallEvent) {
        Task.detached(priority: .background) { [purchases = self.purchases] in
            await purchases.track(paywallEvent: event)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private final class NotConfiguredPurchases: PaywallPurchasesType {

    let purchasesAreCompletedBy: PurchasesAreCompletedBy

    let customerInfo: CustomerInfo?

    init(customerInfo: CustomerInfo? = nil, purchasesAreCompletedBy: PurchasesAreCompletedBy) {
        self.customerInfo = customerInfo
        self.purchasesAreCompletedBy = purchasesAreCompletedBy
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        guard let info = customerInfo else { throw ErrorCode.configurationError }
        return info
    }

    func purchase(package: Package) async throws -> PurchaseResultData {
        throw ErrorCode.configurationError
    }

    func restorePurchases() async throws -> CustomerInfo {
        throw ErrorCode.configurationError
    }

    func track(paywallEvent: PaywallEvent) async {}

}

// MARK: - Preference Keys

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseInProgressPreferenceKey: PreferenceKey {

    static var defaultValue: Package?

    static func reduce(value: inout Package?, nextValue: () -> Package?) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RestoreInProgressPreferenceKey: PreferenceKey {

    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchasedResultPreferenceKey: PreferenceKey {

    struct PurchaseResult: Equatable {
        var transaction: StoreTransaction?
        var customerInfo: CustomerInfo
        var userCancelled: Bool

        init(data: PurchaseResultData) {
            self.transaction = data.transaction
            self.customerInfo = data.customerInfo
            self.userCancelled = data.userCancelled
        }

        init?(data: PurchaseResultData?) {
            guard let data else { return nil }
            self.init(data: data)
        }
    }

    static var defaultValue: PurchaseResult?

    static func reduce(value: inout PurchaseResult?, nextValue: () -> PurchaseResult?) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RestoredCustomerInfoPreferenceKey: PreferenceKey {

    static var defaultValue: CustomerInfo?

    static func reduce(value: inout CustomerInfo?, nextValue: () -> CustomerInfo?) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseErrorPreferenceKey: PreferenceKey {

    static var defaultValue: NSError?

    static func reduce(value: inout NSError?, nextValue: () -> NSError?) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RestoreErrorPreferenceKey: PreferenceKey {

    static var defaultValue: NSError?

    static func reduce(value: inout NSError?, nextValue: () -> NSError?) {
        value = nextValue()
    }

}

// MARK: Environment keys

/// `EnvironmentKey` for storing closure triggered when paywall should be dismissed.
struct RequestedDismissalKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var onRequestedDismissal: (() -> Void)? {
        get { self[RequestedDismissalKey.self] }
        set { self[RequestedDismissalKey.self] = newValue }
    }
}

// MARK: -

private extension CustomerInfo {

    var hasActiveSubscriptionsOrNonSubscriptions: Bool {
        return !self.activeSubscriptions.isEmpty || !self.nonSubscriptions.isEmpty
    }

}
