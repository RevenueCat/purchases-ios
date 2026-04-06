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
final class PaywallEventTracker {
    typealias EventDispatcher = @Sendable (@Sendable @escaping () async -> Void) -> Void

    @Sendable static func dispatcher() -> EventDispatcher {
        return { function in
            Task.detached(priority: .background, operation: function)
        }
    }

    private let purchases: PaywallPurchasesType
    private let eventDispatcher: EventDispatcher

    private var eventData: PaywallEvent.Data?
    private var hasTrackedClose: Bool = false

    init(
        purchases: PaywallPurchasesType = Purchases.shared,
        eventDispatcher: @escaping EventDispatcher = PaywallEventTracker.dispatcher()
    ) {
        self.purchases = purchases
        self.eventDispatcher = eventDispatcher
    }

    func trackPaywallImpression(_ eventData: PaywallEvent.Data) {
        // Auto-track close for previous session if it wasn't tracked yet (within same app session).
        // This handles edge cases where onDisappear or deinit didn't fire (SwiftUI bugs, lifecycle issues).
        // Note: Does not recover close events across app restarts - those are permanently lost.
        if self.eventData != nil && !self.hasTrackedClose {
            self.trackPaywallClose()
        }

        self.eventData = eventData
        self.hasTrackedClose = false
        self.track(.impression(.init(), eventData))
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackPaywallClose() -> Bool {
        guard let data = self.eventData, !self.hasTrackedClose else {
            if self.eventData == nil {
                Logger.debug("Attempted to track paywall close but eventData is nil")
            } else if self.hasTrackedClose {
                Logger.debug("Attempted to track paywall close but close was already tracked")
            }
            return false
        }

        self.track(.close(.init(), data))
        self.hasTrackedClose = true
        return true
    }

    /// - Returns: whether the event was tracked
    @discardableResult
    func trackCancelledPurchase(package: Package) -> Bool {
        guard let data = self.eventData else {
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
    func createPurchaseInitiatedEvent(package: Package) -> PaywallEvent? {
        guard let data = self.eventData else {
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
    func trackPurchaseError(package: Package, error: Error) -> Bool {
        guard let data = self.eventData else {
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
    func trackExitOffer(exitOfferType: ExitOfferType, exitOfferingIdentifier: String) -> Bool {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: exitOfferType,
            exitOfferingIdentifier: exitOfferingIdentifier
        )
        self.track(.exitOffer(.init(), data, exitOfferData))
        return true
    }

    /// Tracks a paywall control interaction.
    /// - Parameters:
    ///   - componentType: Category of the control
    ///   - componentName: Optional builder `name` from the paywall JSON; `nil` when the control has no usable name
    ///   - componentValue: Type-specific payload, e.g. `"on"` / `"off"` for a switch,
    ///     a compatibility value for navigable controls, or a button action discriminator (e.g. `"restore_purchases"`)
    ///   - componentURL: Optional destination URL for URL-based controls (terms, privacy, generic links).
    ///   - originIndex: Optional 0-based source index for navigable controls.
    ///   - destinationIndex: Optional 0-based destination index for navigable controls.
    ///   - originContextName: Optional source context name for navigable controls.
    ///   - destinationContextName: Optional destination context name for navigable controls.
    ///   - defaultIndex: Optional 0-based default index for navigable controls.
    /// - Returns: whether the event was tracked
    @discardableResult
    func trackControlInteraction(
        componentType: ControlType,
        componentName: String?,
        componentValue: String,
        componentURL: URL? = nil,
        originIndex: Int? = nil,
        destinationIndex: Int? = nil,
        originContextName: String? = nil,
        destinationContextName: String? = nil,
        defaultIndex: Int? = nil
    ) -> Bool {
        let interactionData = PaywallEvent.ControlInteractionData(
            componentType: componentType,
            componentName: componentName,
            componentValue: componentValue,
            componentURL: componentURL,
            originIndex: originIndex,
            destinationIndex: destinationIndex,
            originContextName: originContextName,
            destinationContextName: destinationContextName,
            defaultIndex: defaultIndex
        )
        return self.trackControlInteraction(interactionData)
    }

    @discardableResult
    func trackControlInteraction(_ interactionData: PaywallEvent.ControlInteractionData) -> Bool {
        guard let data = self.eventData else {
            Logger.warning(Strings.attempted_to_track_event_with_missing_data)
            return false
        }

        self.track(.controlInteraction(.init(), data, interactionData))
        return true
    }

    func track(_ event: PaywallEvent) {
        self.eventDispatcher { [purchases = self.purchases] in
            await purchases.track(paywallEvent: event)
        }
    }

    var controlInteractionLogger: ControlInteractionLogger {
        return .init { [weak self] interactionData in
            return self?.trackControlInteraction(interactionData) ?? false
        }
    }

}

/// Lightweight wrapper so views can emit control interaction events without depending on the full `PurchaseHandler`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ControlInteractionLogger {

    private let action: (PaywallEvent.ControlInteractionData) -> Bool

    init(action: @escaping (PaywallEvent.ControlInteractionData) -> Bool = { _ in false }) {
        self.action = action
    }

    @discardableResult
    func callAsFunction(_ interactionData: PaywallEvent.ControlInteractionData) -> Bool {
        return self.action(interactionData)
    }

}

/// `EnvironmentKey` for storing the paywall control interaction logger.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ControlInteractionLoggerKey: EnvironmentKey {
    static let defaultValue: ControlInteractionLogger = .init()
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var controlInteractionLogger: ControlInteractionLogger {
        get { self[ControlInteractionLoggerKey.self] }
        set { self[ControlInteractionLoggerKey.self] = newValue }
    }
}
