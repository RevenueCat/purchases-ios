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

    private let stateLock = NSLock()
    private var sessions: [SessionID: SessionState] = [:]

    init(
        purchases: PaywallPurchasesType = Purchases.shared,
        eventDispatcher: @escaping EventDispatcher = PaywallEventTracker.dispatcher()
    ) {
        self.purchases = purchases
        self.eventDispatcher = eventDispatcher
    }

    func trackPaywallImpression(_ eventData: PaywallEvent.Data) {
        let sessionID = eventData.sessionIdentifier
        self.stateLock.perform {
            self.removeSessionsWhere { $0.hasTrackedClose }

            if let existing = self.sessions[sessionID],
               existing.eventData != nil,
               !existing.hasTrackedClose {
                _ = self.trackPaywallCloseWhileLocked(sessionID: sessionID)
            }

            self.sessions[sessionID] = SessionState(eventData: eventData, hasTrackedClose: false)
            self.track(.impression(.init(), eventData))
        }
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose(sessionID: SessionID) -> Bool {
        return self.stateLock.perform {
            return self.trackPaywallCloseWhileLocked(sessionID: sessionID)
        }
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackCancelledPurchase(package: Package, sessionID: SessionID) -> Bool {
        guard let data = self.stateLock.perform({ self.sessions[sessionID]?.eventData }) else {
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
        guard let data = self.stateLock.perform({ self.sessions[sessionID]?.eventData }) else {
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
        guard let data = self.stateLock.perform({ self.sessions[sessionID]?.eventData }) else {
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
        guard let data = self.stateLock.perform({ self.sessions[sessionID]?.eventData }) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: exitOfferType,
            exitOfferingIdentifier: exitOfferingIdentifier
        )
        self.track(.exitOffer(.init(), data, exitOfferData))
        self.stateLock.perform {
            self.sessions.removeValue(forKey: sessionID)
        }
        return true
    }

    /// Drops stored paywall state for `sessionID` (e.g. when the host resets purchase session state).
    func discardSession(sessionID: SessionID) {
        self.stateLock.perform {
            self.sessions.removeValue(forKey: sessionID)
        }
    }

    @discardableResult
    func trackComponentInteraction(
        _ interactionData: PaywallEvent.ComponentInteractionData,
        sessionID: SessionID
    ) -> Bool {
        guard let entry = self.stateLock.perform({ self.sessions[sessionID] }),
              let data = entry.eventData,
              !entry.hasTrackedClose else {
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

    private func removeSessionsWhere(_ shouldRemove: (SessionState) -> Bool) {
        self.sessions = self.sessions.filter { !shouldRemove($0.value) }
    }

    private func trackPaywallCloseWhileLocked(sessionID: SessionID) -> Bool {
        guard var entry = self.sessions[sessionID],
              let data = entry.eventData,
              !entry.hasTrackedClose else {
            if self.sessions[sessionID]?.eventData == nil {
                Logger.debug("Attempted to track paywall close but eventData is nil for session \(sessionID)")
            } else if self.sessions[sessionID]?.hasTrackedClose == true {
                Logger.debug("Attempted to track paywall close but close was already tracked for session \(sessionID)")
            }
            return false
        }

        self.track(.close(.init(), data))
        entry.hasTrackedClose = true
        self.sessions[sessionID] = entry
        return true
    }

    private struct SessionState {
        var eventData: PaywallEvent.Data?
        var hasTrackedClose: Bool = false
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

private extension NSLock {

    @discardableResult
    func perform<T>(_ block: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }

        return try block()
    }

}
