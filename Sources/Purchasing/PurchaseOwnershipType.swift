//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseOwnershipType.swift
//
//  Created by Joshua Liebowitz on 6/24/21.
//

import Foundation
import StoreKit

/// The types used to describe whether a transaction was purchased by the user,
/// or is available to them through Family Sharing.
@objc(RCPurchaseOwnershipType) public enum PurchaseOwnershipType: Int {

    /**
     The purchase was made directly by this user.
     */
    case purchased = 0
    /**
     The purchase has been shared to this user by a family member.
     */
    case familyShared = 1

    /**
     The ownership type could not be determined.
     */
    case unknown = 2

    /**
     The user has access to the purchase through an organization.
     */
    case assigned = 3

}

extension PurchaseOwnershipType: CaseIterable {}
extension PurchaseOwnershipType: Sendable {}

extension PurchaseOwnershipType: DefaultValueProvider {

    static let defaultValue: Self = .purchased

}

internal extension PurchaseOwnershipType {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    static func from(storeKitOwnershipType: StoreKit.Transaction.OwnershipType) -> PurchaseOwnershipType {
        switch storeKitOwnershipType {
        case .familyShared:
            return .familyShared
        #if compiler(>=6.4)
        case .assigned:
            return .assigned
        #endif
        default:
            return .purchased
        }
    }

}
