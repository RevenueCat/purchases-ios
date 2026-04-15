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

    #if DEBUG
    /// Artificial delay at the start of each `PaywallEventTrackerState` actor call.
    /// Set to e.g. `500_000_000` (0.5s) to stress-test UI. Default `0` = disabled. Release builds always skip this.
    static var simulatedActorAccessDelayNanoseconds: UInt64 = 5_000_000_000
    #endif

    @Sendable static func dispatcher() -> EventDispatcher {
        return { function in
            Task.detached(priority: .background, operation: function)
        }
    }

    private let purchases: PaywallPurchasesType
    private let eventDispatcher: EventDispatcher
    private let outboundFifo: PaywallOutboundFifo

    private let state = PaywallEventTrackerState()

    init(
        purchases: PaywallPurchasesType = Purchases.shared,
        eventDispatcher: @escaping EventDispatcher = PaywallEventTracker.dispatcher()
    ) {
        self.purchases = purchases
        self.eventDispatcher = eventDispatcher
        self.outboundFifo = PaywallOutboundFifo(purchases: purchases, dispatcher: eventDispatcher)
    }

    func trackPaywallImpression(_ eventData: PaywallEvent.Data) async {
        Self.logAsyncStateAccess("trackPaywallImpression.prepare")
        if let closeData = await self.state.prepareForPaywallImpression(eventData) {
            Self.logAsyncStateAccess("trackPaywallImpression.autoClose")
            await self.track(.close(.init(), closeData))
        }

        Self.logAsyncStateAccess("trackPaywallImpression.impression")
        await self.track(.impression(.init(), eventData))
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose(sessionID: SessionID) async -> Bool {
        Self.logAsyncStateAccess("trackPaywallClose")
        switch await self.state.trackPaywallClose(sessionID: sessionID) {
        case let .tracked(data):
            await self.track(.close(.init(), data))
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
    func trackCancelledPurchase(package: Package, sessionID: SessionID) async -> Bool {
        Self.logAsyncStateAccess("trackCancelledPurchase")
        guard let data = await self.state.eventData(for: sessionID) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let cancelData = data.withPurchaseInfo(
            packageId: package.identifier,
            productId: package.storeProduct.productIdentifier,
            errorCode: nil,
            errorMessage: nil
        )
        await self.track(.cancel(.init(), cancelData))
        return true
    }

    /// Creates a purchase-initiated paywall event for the given package.
    /// - Returns: the event, or `nil` if event data is unavailable.
    func createPurchaseInitiatedEvent(package: Package, sessionID: SessionID) async -> PaywallEvent? {
        Self.logAsyncStateAccess("createPurchaseInitiatedEvent")
        guard let data = await self.state.eventData(for: sessionID) else {
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
    func trackPurchaseError(package: Package, error: Error, sessionID: SessionID) async -> Bool {
        Self.logAsyncStateAccess("trackPurchaseError")
        guard let data = await self.state.eventData(for: sessionID) else {
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
        await self.track(.purchaseError(.init(), purchaseData))
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
    ) async -> Bool {
        Self.logAsyncStateAccess("trackExitOffer.read")
        guard let data = await self.state.eventData(for: sessionID) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: exitOfferType,
            exitOfferingIdentifier: exitOfferingIdentifier
        )
        await self.track(.exitOffer(.init(), data, exitOfferData))
        Self.logAsyncStateAccess("trackExitOffer.removeSession")
        await self.state.removeSession(sessionID: sessionID)
        return true
    }

    /// Drops stored paywall state for `sessionID` (e.g. when the host resets purchase session state).
    func discardSession(sessionID: SessionID) async {
        Self.logAsyncStateAccess("discardSession")
        await self.state.removeSession(sessionID: sessionID)
    }

    @discardableResult
    func trackComponentInteraction(
        _ interactionData: PaywallEvent.ComponentInteractionData,
        sessionID: SessionID
    ) async -> Bool {
        Self.logAsyncStateAccess("trackComponentInteraction")
        guard let data = await self.state.componentInteractionData(for: sessionID) else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        await self.track(.componentInteraction(.init(), data, interactionData))
        return true
    }

    func track(_ event: PaywallEvent) async {
        await self.outboundFifo.enqueue(event)
    }

    func componentInteractionLogger(sessionID: SessionID) -> ComponentInteractionLogger {
        return .init { [weak self] interactionData in
            guard let self else { return }
            Task {
                _ = await self.trackComponentInteraction(interactionData, sessionID: sessionID)
            }
        }
    }

    private static func logAsyncStateAccess(_ step: String) {
        Logger.debug("[PaywallEventTracker] async state: \(step)")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private actor PaywallEventTrackerState {

    typealias SessionID = PaywallEvent.SessionID

    private var sessions: [SessionID: SessionState] = [:]

    private func applyDebugSimulatedActorDelayIfNeeded() async {
        #if DEBUG
        let delay = PaywallEventTracker.simulatedActorAccessDelayNanoseconds
        guard delay > 0 else { return }
        try? await Task.sleep(nanoseconds: delay)
        #endif
    }

    func prepareForPaywallImpression(_ eventData: PaywallEvent.Data) async -> PaywallEvent.Data? {
        await self.applyDebugSimulatedActorDelayIfNeeded()
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

    func trackPaywallClose(sessionID: SessionID) async -> CloseTrackingResult {
        await self.applyDebugSimulatedActorDelayIfNeeded()
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

    func eventData(for sessionID: SessionID) async -> PaywallEvent.Data? {
        await self.applyDebugSimulatedActorDelayIfNeeded()
        return self.sessions[sessionID]?.eventData
    }

    func componentInteractionData(for sessionID: SessionID) async -> PaywallEvent.Data? {
        await self.applyDebugSimulatedActorDelayIfNeeded()
        guard let entry = self.sessions[sessionID],
              let data = entry.eventData,
              !entry.hasTrackedClose else {
            return nil
        }

        return data
    }

    func removeSession(sessionID: SessionID) async {
        await self.applyDebugSimulatedActorDelayIfNeeded()
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

/// `FIFO outbound delivery`
/// Serializes `purchases.track(paywallEvent:)` so events are delivered in strict enqueue order
/// regardless of how many concurrent callers produce them.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private actor PaywallOutboundFifo {

    private let purchases: PaywallPurchasesType
    private let dispatcher: PaywallEventTracker.EventDispatcher
    private var queue: [PaywallEvent] = []

    init(purchases: PaywallPurchasesType, dispatcher: @escaping PaywallEventTracker.EventDispatcher) {
        self.purchases = purchases
        self.dispatcher = dispatcher
    }

    func enqueue(_ event: PaywallEvent) async {
        self.queue.append(event)
        while !self.queue.isEmpty {
            let next = self.queue.removeFirst()
            await self.deliver(next)
        }
    }

    private func deliver(_ event: PaywallEvent) async {
        let purchases = self.purchases
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.dispatcher {
                Task {
                    await purchases.track(paywallEvent: event)
                    continuation.resume()
                }
            }
        }
    }
}

/// Lightweight wrapper so views can emit control interaction events without depending on the full `PurchaseHandler`.
/// Logging is scheduled with `Task` from ``PaywallEventTracker/componentInteractionLogger(sessionID:)``; call sites may
/// invoke this synchronously without blocking UI.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ComponentInteractionLogger {

    private let action: @Sendable (PaywallEvent.ComponentInteractionData) -> Void

    init(action: @escaping @Sendable (PaywallEvent.ComponentInteractionData) -> Void = { _ in }) {
        self.action = action
    }

    func callAsFunction(_ interactionData: PaywallEvent.ComponentInteractionData) {
        self.action(interactionData)
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
