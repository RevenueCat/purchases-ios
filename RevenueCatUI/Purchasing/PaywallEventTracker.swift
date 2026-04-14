//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventTracker.swift
//
//  Created by RevenueCat on 4/6/26.
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallEventTracker: @unchecked Sendable {
    typealias EventDispatcher = @Sendable (@Sendable @escaping () async -> Void) -> Void
    typealias SessionID = PaywallEvent.SessionID

    static let shared = PaywallEventTracker()

    @Sendable static func dispatcher() -> EventDispatcher {
        return { function in
            Task.detached(priority: .background, operation: function)
        }
    }

    private let purchases: PaywallPurchasesType
    private let eventDispatcher: EventDispatcher

    private let state = PaywallEventTrackerState()

    init(
        purchases: PaywallPurchasesType = Purchases.shared,
        eventDispatcher: @escaping EventDispatcher = PaywallEventTracker.dispatcher()
    ) {
        self.purchases = purchases
        self.eventDispatcher = eventDispatcher
    }

    func trackPaywallImpression(_ eventData: PaywallEvent.Data) {
        if let closeData = self.withState(or: nil, { state in
            await state.prepareForPaywallImpression(eventData)
        }) {
            self.track(.close(.init(), closeData))
        }

        self.track(.impression(.init(), eventData))
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose(sessionID: SessionID) -> Bool {
        switch self.withState(or: .missingEventData, { state in
            await state.trackPaywallClose(sessionID: sessionID)
        }) {
        case let .tracked(data):
            self.track(.close(.init(), data))
            return true

        case .missingEventData:
            Logger.debug("Attempted to track paywall close but eventData is nil for session \(sessionID)")
            return false

        case .alreadyTrackedClose:
            Logger.debug("Attempted to track paywall close but close was already tracked for session \(sessionID)")
            return false
        }
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackCancelledPurchase(package: Package, sessionID: SessionID) -> Bool {
        guard let data = self.withState(or: nil, { state in
            await state.eventData(for: sessionID)
        }) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let cancelData = data.withPurchaseInfo(
            packageId: package.identifier,
            productId: package.storeProduct.productIdentifier,
            errorCode: nil,
            errorMessage: nil
        )
        self.track(.cancel(.init(), cancelData))
        return true
    }

    /// Creates a purchase-initiated paywall event for the given package.
    /// - Returns: the event, or `nil` if event data is unavailable.
    func createPurchaseInitiatedEvent(package: Package, sessionID: SessionID) -> PaywallEvent? {
        guard let data = self.withState(or: nil, { state in
            await state.eventData(for: sessionID)
        }) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return nil
        }

        let purchaseData = data.withPurchaseInfo(
            packageId: package.identifier,
            productId: package.storeProduct.productIdentifier,
            errorCode: nil,
            errorMessage: nil
        )
        return PaywallEvent.purchaseInitiated(.init(), purchaseData)
    }

    /// Tracks a purchase error event.
    /// - Parameters:
    ///   - package: The package that was being purchased
    ///   - error: The error that occurred
    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPurchaseError(package: Package, error: Error, sessionID: SessionID) -> Bool {
        guard let data = self.withState(or: nil, { state in
            await state.eventData(for: sessionID)
        }) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let nsError = error as NSError
        let purchaseData = data.withPurchaseInfo(
            packageId: package.identifier,
            productId: package.storeProduct.productIdentifier,
            errorCode: nsError.code,
            errorMessage: error.localizedDescription
        )
        self.track(.purchaseError(.init(), purchaseData))
        return true
    }

    /// Tracks an exit offer event and clears the pending exit offer flag.
    /// - Parameters:
    ///   - exitOfferType: The type of exit offer
    ///   - exitOfferingIdentifier: The offering identifier of the exit offer
    /// - Returns: whether the event was tracked
    @discardableResult
    func trackExitOffer(
        exitOfferType: ExitOfferType,
        exitOfferingIdentifier: String,
        sessionID: SessionID
    ) -> Bool {
        guard let data = self.withState(or: nil, { state in
            await state.eventData(for: sessionID)
        }) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: exitOfferType,
            exitOfferingIdentifier: exitOfferingIdentifier
        )
        self.track(.exitOffer(.init(), data, exitOfferData))
        self.withState(or: (), { state in
            await state.removeSession(sessionID: sessionID)
        })
        return true
    }

    /// Drops stored paywall state for `sessionID` (e.g. when the host resets purchase session state).
    func discardSession(sessionID: SessionID) {
        self.withState(or: (), { state in
            await state.removeSession(sessionID: sessionID)
        })
    }

    @discardableResult
    func trackComponentInteraction(
        _ interactionData: PaywallEvent.ComponentInteractionData,
        sessionID: SessionID
    ) -> Bool {
        guard let data = self.withState(or: nil, { state in
            await state.componentInteractionData(for: sessionID)
        }) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        self.track(.componentInteraction(.init(), data, interactionData))
        return true
    }

    func track(_ event: PaywallEvent) {
        self.eventDispatcher { [purchases = self.purchases] in
            await purchases.track(paywallEvent: event)
        }
    }

    func componentInteractionLogger(sessionID: SessionID) -> ComponentInteractionLogger {
        return .init { [weak self] interactionData in
            return self?.trackComponentInteraction(interactionData, sessionID: sessionID) ?? false
        }
    }

    private func withState<T: Sendable>(
        or fallback: @autoclosure () -> T,
        _ operation: @escaping @Sendable (PaywallEventTrackerState) async -> T
    ) -> T {
        let access = SynchronousStateAccess<T>()
        Self.startStateAccessTask { [state = self.state] in
            access.complete(with: await operation(state))
        }

        return access.wait(or: fallback())
    }

    private static func startStateAccessTask(
        operation: @escaping @Sendable () async -> Void
    ) {
        Task.detached(priority: Task.currentPriority) {
            await operation()
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private actor PaywallEventTrackerState {

    typealias SessionID = PaywallEvent.SessionID

    private var sessions: [SessionID: SessionState] = [:]

    func prepareForPaywallImpression(_ eventData: PaywallEvent.Data) -> PaywallEvent.Data? {
        self.removeSessionsWhere { $0.hasTrackedClose }

        let sessionID = eventData.sessionIdentifier
        let closeData: PaywallEvent.Data?
        if let existing = self.sessions[sessionID],
           let data = existing.eventData,
           !existing.hasTrackedClose {
            closeData = data
        } else {
            closeData = nil
        }

        self.sessions[sessionID] = .init(eventData: eventData, hasTrackedClose: false)

        return closeData
    }

    func trackPaywallClose(sessionID: SessionID) -> CloseTrackingResult {
        guard var entry = self.sessions[sessionID] else {
            return .missingEventData
        }
        guard let data = entry.eventData else {
            return .missingEventData
        }
        guard !entry.hasTrackedClose else {
            return .alreadyTrackedClose
        }

        entry.hasTrackedClose = true
        self.sessions[sessionID] = entry

        return .tracked(data)
    }

    func eventData(for sessionID: SessionID) -> PaywallEvent.Data? {
        return self.sessions[sessionID]?.eventData
    }

    func componentInteractionData(for sessionID: SessionID) -> PaywallEvent.Data? {
        guard let entry = self.sessions[sessionID],
              let data = entry.eventData,
              !entry.hasTrackedClose else {
            return nil
        }

        return data
    }

    func removeSession(sessionID: SessionID) {
        self.sessions.removeValue(forKey: sessionID)
    }

    private func removeSessionsWhere(_ shouldRemove: (SessionState) -> Bool) {
        self.sessions = self.sessions.filter { !shouldRemove($0.value) }
    }

    private struct SessionState {
        var eventData: PaywallEvent.Data?
        var hasTrackedClose: Bool = false
    }

    enum CloseTrackingResult: Sendable {
        case tracked(PaywallEvent.Data)
        case missingEventData
        case alreadyTrackedClose
    }

}

private final class SynchronousStateAccess<T>: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    var value: T?

    func complete(with value: T) {
        self.value = value
        self.semaphore.signal()
    }

    func wait(or fallback: @autoclosure () -> T) -> T {
        self.semaphore.wait()

        guard let value = self.value else {
            Logger.warning(Strings.paywall_event_tracker_state_access_failed)
            return fallback()
        }

        return value
    }
}

/// Lightweight wrapper so views can emit control interaction events without depending on the full `PurchaseHandler`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentInteractionLogger {

    private let action: (PaywallEvent.ComponentInteractionData) -> Bool

    init(action: @escaping (PaywallEvent.ComponentInteractionData) -> Bool = { _ in false }) {
        self.action = action
    }

    @discardableResult
    func callAsFunction(_ interactionData: PaywallEvent.ComponentInteractionData) -> Bool {
        return self.action(interactionData)
    }

}

/// `EnvironmentKey` for storing the paywall control interaction logger.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentInteractionLoggerKey: EnvironmentKey {
    static let defaultValue: ComponentInteractionLogger = .init()
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var componentInteractionLogger: ComponentInteractionLogger {
        get { self[ComponentInteractionLoggerKey.self] }
        set { self[ComponentInteractionLoggerKey.self] = newValue }
    }
}
