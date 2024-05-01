//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ObserverModeManager.swift
//
//  Created by Will Taylor on 4/30/24.

import Foundation
import StoreKit

/// A wrapper that allows managing observer-mode for StoreKit2, synchronized as an `actor`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol StoreKit2ObserverModeManagerType {

    /// Begins observing purchase transactions.
    func beginObservingPurchases()

    /// Sets the delegate to handle observer mode transactions.
    /// - Parameter delegate: An object conforming to `StoreKit2ObserverModeManagerDelegate`
    /// that will handle the observed transactions.
    func set(delegate: StoreKit2ObserverModeManagerDelegate)

}

/// A delegate protocol for handling verified transactions in observer mode.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol StoreKit2ObserverModeManagerDelegate: AnyObject, Sendable {

    /// Handles a verified transaction with its corresponding JWS representation.
    /// - Parameters:
    ///   - verifiedTransaction: The verified transaction to be processed.
    ///   - jwsRepresentation: The JSON Web Signature representation of the transaction.
    func handleSK2ObserverModeTransaction(
        verifiedTransaction: StoreKit.Transaction,
        jwsRepresentation: String
    ) async throws
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StoreKit2ObserverModeManager: StoreKit2ObserverModeManagerType {

    private var delegate: StoreKit2ObserverModeManagerDelegate?
    private let notificationCenter: NotificationCenter
    private let storeKit2ObserverModePurchaseListener: SK2ObserverModePurchaseDetectorType

    init(
        storeKit2ObserverModePurchaseListener: SK2ObserverModePurchaseDetectorType,
        notificationCenter: NotificationCenter
    ) {
        self.storeKit2ObserverModePurchaseListener = storeKit2ObserverModePurchaseListener
        self.notificationCenter = notificationCenter
    }

    func beginObservingPurchases() {
        if let applicationDidBecomeActiveNotification = SystemInfo.applicationDidBecomeActiveNotification {
            notificationCenter.addObserver(self,
                                           selector: #selector(applicationDidBecomeActive),
                                           name: applicationDidBecomeActiveNotification,
                                           object: nil)
        }
    }

    @objc func applicationDidBecomeActive() {
        Task {
            await storeKit2ObserverModePurchaseListener.detectUnobservedTransactions(delegate: self.delegate)
        }
    }

    func set(delegate: any StoreKit2ObserverModeManagerDelegate) {
        self.delegate = delegate
    }
}
