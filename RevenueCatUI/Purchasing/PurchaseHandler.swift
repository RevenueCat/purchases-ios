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

/// A class that can be used to report the result of a purchase.
public class PurchaseResultReporter: Equatable {

    let storeProduct: StoreProduct
    let reportPurchaseResultCallback: (_ userCancelled: Bool, _ error: Error?) -> Void

    init(storeProduct: StoreProduct, reportPurchaseResult: @escaping (_: Bool, _: Error?) -> Void) {
        self.storeProduct = storeProduct
        self.reportPurchaseResultCallback = reportPurchaseResult
    }

    /// Use this method to report the result of the purchase.
    /// - Parameters:
    ///   - userCancelled: A boolean indicating whether the user cancelled the purchase.
    ///   - error: An optional error object if an error occurred during the purchase.
    public func reportResult(userCancelled: Bool, error: Error?) {
        reportPurchaseResultCallback(userCancelled, error)
    }

    /// Checks whether two `PurchaseResultReporter` instances are equal.
    /// They are considered equal if the object represents the same `StoreProduct`
    public static func == (lhs: PurchaseResultReporter, rhs: PurchaseResultReporter) -> Bool {
        return lhs.storeProduct == rhs.storeProduct
    }

}

/// A class that can be used to report the result of a restoring purchases.
public class RestoreResultReporter: Equatable {

    let reportRestoreResultCallback: (_ success: Bool, _ error: Error?) -> Void

    init(callback: @escaping (Bool, Error?) -> Void) {
        self.reportRestoreResultCallback = callback
    }

    /// Use this method to report the result of a restore operation.
    /// - Parameters:
    ///   - success: A boolean indicating whether the restore operation was successful.
    ///   - error: An optional error object if an error occurred during the restore operation.
    public func reportResult(success: Bool, error: Error?) {
        reportRestoreResultCallback(success, error)
    }

    /// Returns true if objects are the same object (same memory address); false otherwise.
    public static func == (lhs: RestoreResultReporter, rhs: RestoreResultReporter) -> Bool {
        return lhs === rhs
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
final class PurchaseHandler: ObservableObject {

    private let purchases: PaywallPurchasesType

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

    /// When `purchased` becomes `true`, this will include the `CustomerInfo` associated to it.
    @Published
    fileprivate(set) var purchaseResult: PurchaseResultData?

    /// Information used to perform a purchase by the app (rather than by RevenueCat)
    @Published
    fileprivate(set) var performPurchase: PurchaseResultReporter?

    /// Information used to perform restoring a purchase by the app (rather than by RevenueCat)
    @Published
    fileprivate(set) var performRestore: RestoreResultReporter?

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

    private var externalRestorePurchaseContinuation: CheckedContinuation<Bool, Error>?

    convenience init(purchases: Purchases = .shared) {
        self.init(isConfigured: true, purchases: purchases)
    }

    init(
        isConfigured: Bool = true,
        purchases: PaywallPurchasesType
    ) {
        self.isConfigured = isConfigured
        self.purchases = purchases
    }

    /// Returns a new instance of `PurchaseHandler` using `Purchases.shared` if `Purchases`
    /// has been configured, and using a PurchaseHandler that cannot be used for purchases otherwise.
    // @PublicForExternalTesting
    static func `default`() -> Self {
        return Purchases.isConfigured ? .init() : Self.notConfigured()
    }

    private static func notConfigured() -> Self {
        return .init(isConfigured: false, purchases: NotConfiguredPurchases())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    // MARK: - Purchase

    @MainActor
    func purchase(package: Package) async throws -> PurchaseResultData {
        switch self.purchases.purchasesAreCompletedBy {
        case .revenueCat:
            return try await performPurchase(package: package)
        case .myApp:
            return try await performExternalPurchaseLogic(package: package)
        }
    }

    @MainActor
    func performPurchase(package: Package) async throws -> PurchaseResultData {
        Logger.debug(Strings.executing_purchase_logic)
        self.packageBeingPurchased = package
        self.purchaseResult = nil
        self.purchaseError = nil

        self.startAction()
        defer {
            self.packageBeingPurchased = nil
            self.actionInProgress = false
        }

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

            return result
        } catch {
            self.purchaseError = error
            throw error
        }
    }

    @MainActor
    func performExternalPurchaseLogic(package: Package) async throws -> PurchaseResultData {
        Logger.debug(Strings.executing_external_purchase_logic)

        self.packageBeingPurchased = package
        self.purchaseResult = nil
        self.purchaseError = nil
        self.performPurchase = PurchaseResultReporter(storeProduct: package.storeProduct,
                                                      reportPurchaseResult: self.reportExternalPurchaseResult)

        self.startAction()

        return PurchaseResultData(nil, try await self.purchases.customerInfo(), false)
    }

    @MainActor
    func reportExternalPurchaseResult(_ userCancelled: Bool, _ error: Error?) {
        self.actionInProgress = false
        self.performPurchase = nil

        if let error {
            self.purchaseError = error
        } else {
            if userCancelled {
                self.trackCancelledPurchase()
            } else {
                withAnimation(Constants.defaultAnimation) {
                    self.purchased = true
                }
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

        defer {
            self.restoreInProgress = false
            self.actionInProgress = false
        }

        self.restoreInProgress = true
        self.restoredCustomerInfo = nil
        self.restoreError = nil

        DispatchQueue.main.async {
            // this triggers the view's `.handlePurchaseAndRestore` function, and its callback must be called
            // after the continuation is set below
            self.performRestore = RestoreResultReporter(callback: self.reportExternalRestoreResult)
        }

        self.startAction()

        let success = try await withCheckedThrowingContinuation { continuation in
            externalRestorePurchaseContinuation = continuation
        }

        return (info: try await self.purchases.customerInfo(), success)
    }

    @MainActor
    func reportExternalRestoreResult(success: Bool, error: Error?) {
        if let error {
            self.restoreError = error
            externalRestorePurchaseContinuation?.resume(throwing: error)
        } else {
            externalRestorePurchaseContinuation?.resume(returning: success)
        }
        externalRestorePurchaseContinuation = nil
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

    var purchasesAreCompletedBy: PurchasesAreCompletedBy {
        get { return .myApp }
        set { _ = newValue }
    }

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        throw ErrorCode.configurationError
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
struct HandlePurchasePreferenceKey: PreferenceKey {

    static var defaultValue: PurchaseResultReporter?

    static func reduce(value: inout PurchaseResultReporter?, nextValue: () -> PurchaseResultReporter?) {
        value = nextValue()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct HandleRestorePreferenceKey: PreferenceKey {

    static var defaultValue: RestoreResultReporter?

    static func reduce(value: inout RestoreResultReporter?, nextValue: () -> RestoreResultReporter?) {
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
