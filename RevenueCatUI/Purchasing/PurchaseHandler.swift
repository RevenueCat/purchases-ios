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
    private let paywallEventTracker: PaywallEventTracker

    /// Side-by-side paywalls should use separate `PurchaseHandler` instances so each keeps its own session.
    private var activePaywallSessionID: PaywallEvent.SessionID?

    /// Where responsibility for completing purchases lies
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
    var packageBeingPurchased: Package?

    /// Whether a purchase or restore is currently in progress
    @Published
    var actionTypeInProgress: ActionType?

    /// Whether a purchase or restore is currently in progress
    var actionInProgress: Bool {
        return actionTypeInProgress != nil
    }

    /// The result of a purchase completed in the current session.
    /// This is reset when a new paywall session starts, allowing us to track
    /// whether a purchase happened during this specific paywall presentation.
    /// More extensible than a boolean - gives access to full result data for
    /// potential future exit offer triggers (e.g., based on specific products).
    @Published
    fileprivate(set) var sessionPurchaseResult: PurchaseResultData?

    /// Whether a purchase was successfully completed in the current session.
    /// Convenience property for checking if we should skip exit offers.
    var hasPurchasedInSession: Bool {
        guard let result = sessionPurchaseResult else { return false }
        return !result.userCancelled
    }

    /// When a purchase completes, this will include the `CustomerInfo`
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

    convenience init(purchases: Purchases = .shared,
                     performPurchase: PerformPurchase? = nil,
                     performRestore: PerformRestore? = nil,
                     purchaseResultPublisher: AnyPublisher<PurchaseResultData, Never> = NotificationCenter
                         .default
                         .purchaseCompletedPublisher(),
                     eventTracker: PaywallEventTracker = .shared
    ) {
        self.init(isConfigured: true,
                  purchases: purchases,
                  performPurchase: performPurchase,
                  performRestore: performRestore,
                  purchaseResultPublisher: purchaseResultPublisher,
                  eventTracker: eventTracker
        )
    }

    init(
        isConfigured: Bool = true,
        purchases: PaywallPurchasesType,
        performPurchase: PerformPurchase? = nil,
        performRestore: PerformRestore? = nil,
        purchaseResultPublisher: AnyPublisher<PurchaseResultData, Never> = NotificationCenter
            .default
            .purchaseCompletedPublisher(),
        eventTracker: PaywallEventTracker
    ) {
        self.isConfigured = isConfigured
        self.purchases = purchases
        self.paywallEventTracker = eventTracker
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
        let purchases = NotConfiguredPurchases(
            customerInfo: customerInfo,
            purchasesAreCompletedBy: purchasesAreCompletedBy
        )

        return .init(
            isConfigured: false,
            purchases: purchases,
            performPurchase: performPurchase,
            performRestore: performRestore,
            eventTracker: .init(purchases: purchases)
        )
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

    /// Resets purchase state for a new paywall session.
    ///
    /// This is called when a paywall appears to ensure we track purchases for the current session only.
    /// We reset both `sessionPurchaseResult` (used for exit offer logic) and `purchaseResult`
    /// (used for `onPurchaseCompleted` preference) to avoid stale values triggering handlers.
    func resetForNewSession() {
        if let sessionID = self.activePaywallSessionID {
            self.paywallEventTracker.discardSession(sessionID: sessionID)
        }
        self.sessionPurchaseResult = nil
        self.purchaseResult = nil
        self.activePaywallSessionID = nil
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

    func cachedInitialOffering(for content: PaywallViewConfiguration.Content) -> Offering? {
        switch content {
        case let .offering(offering):
            return offering
        case .defaultOffering:
            return self.purchases.cachedOfferings?.current
        case let .offeringIdentifier(identifier, presentedOfferingContext):
            #if !os(tvOS)
            if ProcessInfo.processInfo.workflowsEndpointEnabled {
                return nil
            }
            #endif
            let offering = self.purchases.cachedOfferings?.offering(identifier: identifier)

            if let presentedOfferingContext {
                return offering?.withPresentedOfferingContext(presentedOfferingContext)
            }

            return offering
        }
    }

    func resolveOffering(for content: PaywallViewConfiguration.Content) async -> Offering? {
        if case let .offering(offering) = content {
            return offering
        }

        do {
            return try await self.resolveOfferingOrThrow(for: content)
        } catch {
            Logger.error(Strings.errorFetchingOfferings(error))
            return nil
        }
    }

    func resolveOfferingOrThrow(for content: PaywallViewConfiguration.Content) async throws -> Offering {
        switch content {
        case let .offering(offering):
            return offering
        case .defaultOffering:
            return try await self.purchases.offerings().current.orThrow(PaywallError.noCurrentOffering)
        case let .offeringIdentifier(identifier, presentedOfferingContext):
            return try await self.resolveOfferingIdentifier(
                identifier: identifier,
                presentedOfferingContext: presentedOfferingContext
            )
        }
    }

    private func resolveOfferingIdentifier(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext?
    ) async throws -> Offering {
        #if !os(tvOS)
        if ProcessInfo.processInfo.workflowsEndpointEnabled {
            return try await self.resolveWorkflowOfferingIdentifier(
                identifier: identifier,
                presentedOfferingContext: presentedOfferingContext
            )
        }
        #endif
        let offering = try await self.purchases.offerings()
            .offering(identifier: identifier)
            .orThrow(PaywallError.offeringNotFound(identifier: identifier))

        if let presentedOfferingContext {
            return offering.withPresentedOfferingContext(presentedOfferingContext)
        }

        return offering
    }

    #if !os(tvOS)
    private func resolveWorkflowOfferingIdentifier(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext?
    ) async throws -> Offering {
        return try await resolveWorkflowContext(
            identifier: identifier,
            presentedOfferingContext: presentedOfferingContext
        ).offering
    }

    func resolveWorkflowContext(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext?
    ) async throws -> (context: WorkflowContext, offering: Offering) {
        guard ProcessInfo.processInfo.workflowsEndpointEnabled else {
            throw PaywallError.offeringNotFound(identifier: identifier)
        }

        async let fetchResultTask = self.purchases.workflow(forOfferingIdentifier: identifier)
        async let allOfferingsTask = self.purchases.offerings()

        let (fetchResult, allOfferings) = try await (fetchResultTask, allOfferingsTask)
        let workflow = fetchResult.workflow

        guard let step = workflow.steps[workflow.initialStepId],
              let screenID = step.screenId,
              let screen = workflow.screens[screenID] else {
            throw PaywallError.offeringNotFound(identifier: identifier)
        }

        let resolvedOfferingId = screen.offeringIdentifier
        let baseOffering = try allOfferings
            .offering(identifier: resolvedOfferingId)
            .orThrow(PaywallError.offeringNotFound(identifier: resolvedOfferingId ?? identifier))

        let paywallComponents = WorkflowScreenMapper.toPaywallComponents(
            screen: screen,
            uiConfig: workflow.uiConfig
        )

        let initialOffering = baseOffering.withPaywallComponents(paywallComponents)

        let offering: Offering
        if let presentedOfferingContext {
            offering = initialOffering.withPresentedOfferingContext(presentedOfferingContext)
        } else {
            offering = initialOffering
        }

        let context = WorkflowContext(
            workflow: workflow,
            allOfferings: allOfferings,
            initialOffering: offering,
            presentedOfferingContext: presentedOfferingContext
        )

        return (context, offering)
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
        let paywallEvent = self.createPurchaseInitiatedEvent(package: package)
        if let paywallEvent { self.track(paywallEvent) }

        do {
            let result: PurchaseResultData

            result = try await self.purchases.purchase(package: package,
                                                       promotionalOffer: promotionalOffer,
                                                       paywallEvent: paywallEvent)

            if result.userCancelled {
                self.trackCancelledPurchase(package: package)
            }

            // Set sessionPurchaseResult BEFORE setResult so that handleMainPaywallDismiss
            // sees the correct state when the sheet dismisses.
            // This is set for both successful and cancelled results so that
            // onPurchaseCompleted and onPurchaseCancelled modifiers both work correctly.
            withAnimation(Constants.defaultAnimation) {
                self.sessionPurchaseResult = result
            }

            self.setResult(result)

        } catch {
            self.trackPurchaseError(package: package, error: error)
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
        let paywallEvent = self.createPurchaseInitiatedEvent(package: package)
        if let paywallEvent { self.track(paywallEvent) }
        let productIdentifier = package.storeProduct.productIdentifier
        self.purchases.cachePurchaseData(
            presentedOfferingContext: package.presentedOfferingContext,
            paywallEvent: paywallEvent,
            productIdentifier: productIdentifier
        )

        let result = await externalPurchaseMethod(package)

        if result.userCancelled {
            self.trackCancelledPurchase(package: package)
            self.purchases.clearCachedPurchaseData(productIdentifier: productIdentifier)
        }

        if let error = result.error {
            self.trackPurchaseError(package: package, error: error)
            self.purchases.clearCachedPurchaseData(productIdentifier: productIdentifier)
            self.purchaseError = error
            throw error
        }

        let resultInfo: PurchaseResultData = (transaction: nil,
                                             customerInfo: try await self.purchases.customerInfo(),
                                            userCancelled: result.userCancelled)

        // Set sessionPurchaseResult BEFORE setResult so that handleMainPaywallDismiss
        // sees the correct state when the sheet dismisses.
        // This is set for both successful and cancelled results so that
        // onPurchaseCompleted and onPurchaseCancelled modifiers both work correctly.
        withAnimation(Constants.defaultAnimation) {
            self.sessionPurchaseResult = resultInfo
        }

        self.setResult(resultInfo)

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
        self.activePaywallSessionID = eventData.sessionIdentifier
        self.paywallEventTracker.trackPaywallImpression(eventData)
    }

    func componentInteractionLogger(sessionID: PaywallEvent.SessionID) -> ComponentInteractionLogger {
        return self.paywallEventTracker.componentInteractionLogger(sessionID: sessionID)
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose() -> Bool {
        guard let sessionID = self.activePaywallSessionID else {
            return false
        }
        // Keep `activePaywallSessionID` set after close so `trackExitOffer` can still resolve paywall data.
        return self.paywallEventTracker.trackPaywallClose(sessionID: sessionID)
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    fileprivate func trackCancelledPurchase(package: Package) -> Bool {
        guard let sessionID = self.activePaywallSessionID else {
            return false
        }
        return self.paywallEventTracker.trackCancelledPurchase(package: package, sessionID: sessionID)
    }

    /// Creates a purchase-initiated paywall event for the given package.
    /// - Returns: the event, or `nil` if event data is unavailable.
    func createPurchaseInitiatedEvent(package: Package) -> PaywallEvent? {
        guard let sessionID = self.activePaywallSessionID else {
            return nil
        }
        return self.paywallEventTracker.createPurchaseInitiatedEvent(package: package, sessionID: sessionID)
    }

    /// Tracks a purchase error event.
    /// - Parameters:
    ///   - package: The package that was being purchased
    ///   - error: The error that occurred
    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPurchaseError(package: Package, error: Error) -> Bool {
        guard let sessionID = self.activePaywallSessionID else {
            return false
        }
        return self.paywallEventTracker.trackPurchaseError(package: package, error: error, sessionID: sessionID)
    }

    /// Tracks an exit offer event.
    /// - Parameters:
    ///   - exitOfferType: The type of exit offer
    ///   - exitOfferingIdentifier: The offering identifier of the exit offer
    /// - Returns: whether the event was tracked
    @discardableResult
    func trackExitOffer(exitOfferType: ExitOfferType, exitOfferingIdentifier: String) -> Bool {
        guard let sessionID = self.activePaywallSessionID else {
            return false
        }
        return self.paywallEventTracker.trackExitOffer(
            exitOfferType: exitOfferType,
            exitOfferingIdentifier: exitOfferingIdentifier,
            sessionID: sessionID
        )
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
        let purchases = self.purchases.map(purchase: purchase, restore: restore)
        return .init(
            isConfigured: self.isConfigured,
            purchases: purchases,
            eventTracker: self.paywallEventTracker.withPurchases(purchases)
        )
    }

    func map(
        trackEvent: @escaping (@escaping MockPurchases.TrackEventBlock) -> MockPurchases.TrackEventBlock
    ) -> Self {
        let purchases = self.purchases.map(trackEvent: trackEvent)
        return .init(
            isConfigured: self.isConfigured,
            purchases: purchases,
            eventTracker: self.paywallEventTracker.withPurchases(purchases)
        )
    }

}

#endif

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PurchaseHandler {

    func track(_ event: PaywallEvent) {
        self.paywallEventTracker.track(event)
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

    func offerings() async throws -> Offerings { throw ErrorCode.configurationError }

    var cachedOfferings: Offerings? { nil }

#if !os(tvOS)
    func workflow(forOfferingIdentifier offeringID: String) async throws -> WorkflowDataResult {
        throw ErrorCode.configurationError
    }
#endif

    func customerInfo() async throws -> RevenueCat.CustomerInfo {
        guard let info = customerInfo else { throw ErrorCode.configurationError }
        return info
    }

    func purchase(
        package: Package,
        promotionalOffer: PromotionalOffer?,
        paywallEvent: PaywallEvent?
    ) async throws -> PurchaseResultData {
        throw ErrorCode.configurationError
    }

    func restorePurchases() async throws -> CustomerInfo {
        throw ErrorCode.configurationError
    }

    func track(paywallEvent: PaywallEvent) async {}

    func cachePurchaseData(presentedOfferingContext: PresentedOfferingContext,
                           paywallEvent: PaywallEvent?,
                           productIdentifier: String) {}

    func clearCachedPurchaseData(productIdentifier: String) {}

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

/// `EnvironmentKey` for storing the restore initiated interceptor action.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RestoreInitiatedActionKey: EnvironmentKey {
    static let defaultValue: RestoreInitiatedAction? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var restoreInitiatedAction: RestoreInitiatedAction? {
        get { self[RestoreInitiatedActionKey.self] }
        set { self[RestoreInitiatedActionKey.self] = newValue }
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

#if !os(tvOS)
extension ProcessInfo {

    var workflowsEndpointEnabled: Bool {
        arguments.contains("-EnableWorkflowsEndpoint")
    }

}
#endif
