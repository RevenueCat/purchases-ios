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
}

extension NotificationCenter {
    // swiftlint:disable:next missing_docs
    @_spi(Internal) public func purchaseCompletedPublisher() -> AnyPublisher<PurchaseResultData, Never> {
        self
            .publisher(for: .purchaseCompleted)
            .compactMap { $0.object as? PurchaseResultData }
            .eraseToAnyPublisher()
    }
}
