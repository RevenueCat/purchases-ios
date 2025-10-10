//
//  TransactionNotifications.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 10/9/25.
//

import Foundation

extension Notification.Name {
    /// A notification that states a purchase has completed
    @_spi(Internal) public static let purchaseCompleted = Notification.Name("RevenueCat.PurchaseCompleted")
}
