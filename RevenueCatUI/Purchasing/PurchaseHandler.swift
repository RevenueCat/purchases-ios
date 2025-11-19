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

import Combine
@_spi(Internal) import RevenueCat
import StoreKit
import SwiftUI

// swiftlint:disable file_length

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PurchaseHandler: ObservableObject {

    enum ActionType {

        /// This is a pre-purchase or redeem code step where consuming applications can perform work
        case pendingPurchaseContinuation
        case purchase
        case restore

    }

    private var cancellables: Set<AnyCancellable> = Set()

    private let purchases: PaywallPurchasesType

    /// Where responsibiliy for completing purchases lies
    var purchasesAreCompletedBy: PurchasesAreCompletedBy {
        purchases.purchasesAreCompletedBy
    }

    var subscriptionHistoryTracker: SubscriptionHistoryTracker {
        purchases.subscriptionHistoryTracker
    }

    /// `false` if this `PurchaseHandler` is not backend by a configured `Purchases`instance.
    let isConfigured: Bool

    var preferredLocales: [Locale] {
        return purchases.preferredLocales.map(Locale.init)
    }

    var preferredLocaleOverride: Locale? {
        return purchases.preferredLocaleOverride.map(Locale.init)
    }

    /// Whether a purchase is currently in progress
    @Published
    fileprivate(set) var packageBeingPurchased: Package?

    /// Whether a purchase or restore is currently in progress
    @Published
    fileprivate(set) var actionTypeInProgress: ActionType?

    /// Whether a purchase or restore is currently in progress
    var actionInProgress: Bool {
        return actionTypeInProgress != nil
    }

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
    fileprivate(set) var restoredCustomerInfo: RestoreResult?

    /// Error produced during a purchase.
    @Published
    fileprivate(set) var purchaseError: Error?

    /// Error produced during restoring..
    @Published
    fileprivate(set) var restoreError: Error?

    private var eventData: PaywallEvent.Data?

    convenience init(purchases: Purchases = .shared,
                     performPurchase: PerformPurchase? = nil,
                     performRestore: PerformRestore? = nil,
                     purchaseResultPublisher: AnyPublisher<PurchaseResultData, Never> = NotificationCenter
                         .default
                         .purchaseCompletedPublisher()
    ) {
        self.init(isConfigured: true,
                  purchases: purchases,
                  performPurchase: performPurchase,
                  performRestore: performRestore,
                  purchaseResultPublisher: purchaseResultPublisher
        )
    }

    init(
        isConfigured: Bool = true,
        purchases: PaywallPurchasesType,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil,
        purchaseResultPublisher: AnyPublisher<PurchaseResultData, Never> = NotificationCenter
            .default
            .purchaseCompletedPublisher()
    ) {
        self.isConfigured = isConfigured
        self.purchases = purchases
        self.performPurchase = performPurchase
        self.performRestore = performRestore

        purchaseResultPublisher
            .removeDuplicates(by: PurchaseResultComparator.compare)
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.setResult(result)
            }
            .store(in: &cancellables)
    }

    /// Returns a new instance of `PurchaseHandler` using `Purchases.shared` if `Purchases`
    /// has been configured, and using a PurchaseHandler that cannot be used for purchases otherwise.
    static func `default`(performPurchase: PerformPurchase? = nil,
                          performRestore: PerformRestore? = nil) -> Self {
        return Purchases.isConfigured ? .init(performPurchase: performPurchase,
                                              performRestore: performRestore) :
                                        Self.notConfigured(performPurchase: performPurchase,
                                                           performRestore: performRestore)
    }

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

    private func setResult(_ result: PurchaseResultData) {
        guard !PurchaseResultComparator.compare(purchaseResult, result) else {
            return
        }
        self.purchaseResult = result
    }

    deinit {
        cancellables.removeAll()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {
    func withPendingPurchaseContinuation<T>(_ continuation: () async throws -> T) async rethrows -> T {
        await MainActor.run {
            startAction(.pendingPurchaseContinuation)
        }
        let result = try await continuation()
        await MainActor.run {
            if actionTypeInProgress == .pendingPurchaseContinuation {
                self.actionTypeInProgress = nil
            }
        }
        return result
    }

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func invalidateCustomerInfoCache() {
        self.purchases.invalidateCustomerInfoCache()
    }
#endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PurchaseHandler {

    // MARK: - Purchase

    @MainActor
    func purchase(package: Package) async throws {
        try await purchase(package: package, promotionalOffer: nil)
    }

    @MainActor
    func purchase(package: Package, promotionalOffer: PromotionalOffer?) async throws {
        switch self.purchases.purchasesAreCompletedBy {
        case .revenueCat:
            try await performPurchase(package: package, promotionalOffer: promotionalOffer)
        case .myApp:
            try await performExternalPurchaseLogic(package: package, promotionalOffer: promotionalOffer)
        }
    }

    @MainActor
    func performPurchase(package: Package, promotionalOffer: PromotionalOffer?) async throws {
        Logger.debug(Strings.executing_purchase_logic)
        self.packageBeingPurchased = package
        self.purchaseResult = nil
        self.purchaseError = nil

        defer {
            self.packageBeingPurchased = nil
            self.actionTypeInProgress = nil
        }

        self.startAction(.purchase)

        do {
            let result: PurchaseResultData

            if let promotionalOffer {
                result = try await self.purchases.purchase(package: package, promotionalOffer: promotionalOffer)
            } else {
                result = try await self.purchases.purchase(package: package)
            }

            self.setResult(result)

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
    func performExternalPurchaseLogic(package: Package, promotionalOffer: PromotionalOffer?) async throws {
        Logger.debug(Strings.executing_external_purchase_logic)

        // WIP: Handle promotionalOffer in performPurchase
        guard let externalPurchaseMethod = self.performPurchase else {
            throw PaywallError.performPurchaseAndRestoreHandlersNotDefined(missingBlocks: "performPurchase is")
        }

        self.packageBeingPurchased = package
        self.purchaseResult = nil
        self.purchaseError = nil

        defer {
            self.restoreInProgress = false
            self.actionTypeInProgress = nil
        }

        self.startAction(.purchase)

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

        self.setResult(resultInfo)

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

        self.startAction(.restore)
        defer {
            self.restoreInProgress = false
            self.actionTypeInProgress = nil
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
            self.actionTypeInProgress = nil
        }

        self.restoreInProgress = true
        self.restoredCustomerInfo = nil
        self.restoreError = nil

        self.startAction(.restore)

        let result = await externalRestoreMethod()

        if let error = result.error {
            self.restoreError = error
            throw error
        }

        let customerInfo = try await self.purchases.customerInfo()

        // This is done by `RestorePurchasesButton` when using RevenueCat logic.
        self.setRestored(customerInfo, success: result.success)

        return (info: customerInfo, result.success)
    }

    @MainActor
    func setRestored(_ customerInfo: CustomerInfo, success: Bool) {
        self.restoredCustomerInfo = .init(customerInfo: customerInfo, success: success)
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

    private func startAction(_ type: PurchaseHandler.ActionType) {
        withAnimation(Constants.fastAnimation) {
            self.actionTypeInProgress = type
        }
    }

    struct RestoreResult: Equatable {
        let customerInfo: CustomerInfo
        let success: Bool

        static func == (lhs: RestoreResult, rhs: RestoreResult) -> Bool {
            return lhs.success == rhs.success && lhs.customerInfo === rhs.customerInfo
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

    var preferredLocales: [String] { Locale.preferredLanguages }

    var preferredLocaleOverride: String? { nil }

    var subscriptionHistoryTracker: RevenueCat.SubscriptionHistoryTracker {
        SubscriptionHistoryTracker()
    }

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

    func purchase(package: Package, promotionalOffer: PromotionalOffer) async throws -> PurchaseResultData {
        throw ErrorCode.configurationError
    }

    func restorePurchases() async throws -> CustomerInfo {
        throw ErrorCode.configurationError
    }

    func track(paywallEvent: PaywallEvent) async {}

#if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    func invalidateCustomerInfoCache() {}
#endif

#if !os(tvOS)

    func failedToLoadFontWithConfig(_ fontConfig: UIConfig.FontsConfig) {}

#endif

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

    static var defaultValue: PurchaseHandler.RestoreResult?

    static func reduce(value: inout PurchaseHandler.RestoreResult?, nextValue: () -> PurchaseHandler.RestoreResult?) {
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

/// `EnvironmentKey` for storing the purchase initiated interceptor action.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseInitiatedActionKey: EnvironmentKey {
    static let defaultValue: PurchaseInitiatedAction? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var purchaseInitiatedAction: PurchaseInitiatedAction? {
        get { self[PurchaseInitiatedActionKey.self] }
        set { self[PurchaseInitiatedActionKey.self] = newValue }
    }
}

/// `EnvironmentKey` for storing the offer code redemption initiated interceptor action.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct OfferCodeRedemptionInitiatedActionKey: EnvironmentKey {
    static let defaultValue: OfferCodeRedemptionInitiatedAction? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var offerCodeRedemptionInitiatedAction: OfferCodeRedemptionInitiatedAction? {
        get { self[OfferCodeRedemptionInitiatedActionKey.self] }
        set { self[OfferCodeRedemptionInitiatedActionKey.self] = newValue }
    }
}

// MARK: -

private extension CustomerInfo {

    var hasActiveSubscriptionsOrNonSubscriptions: Bool {
        return !self.activeSubscriptions.isEmpty || !self.nonSubscriptions.isEmpty
    }

}
