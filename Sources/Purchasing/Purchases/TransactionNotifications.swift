//
//  TransactionNotifications.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 10/10/25.
//

import Combine
import Foundation

extension NSNotification.Name {
    /// A notification that states a purchase has completed
    static let purchaseCompleted = Notification.Name("RevenueCat.PurchaseCompleted")

    /// A notification that states the preferred RevenueCatUI locale override changed.
    static let preferredUILocaleOverrideChanged = Notification.Name("RevenueCat.PreferredUILocaleOverrideChanged")
}

extension NotificationCenter {
    /// A publisher that wraps the `purchaseCompleted` notification that will allow us to propagate 
    /// those events for transactions that were not initiated directly by the Purchases SDK 
    /// (like promotional offers)
    ///
    /// - Important: This is not intended for public consumption and should be used with care
    @_spi(Internal) public func purchaseCompletedPublisher() -> AnyPublisher<PurchaseResultData, Never> {
        self
            .publisher(for: .purchaseCompleted)
            .compactMap { $0.object as? PurchaseResultData }
            .eraseToAnyPublisher()
    }

    /// A publisher that wraps the `preferredUILocaleOverrideChanged` notification.
    ///
    /// - Important: This is not intended for public consumption and should be used with care.
    @_spi(Internal) public func preferredUILocaleOverrideChangedPublisher() -> AnyPublisher<Void, Never> {
        self
            .publisher(for: .preferredUILocaleOverrideChanged)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
