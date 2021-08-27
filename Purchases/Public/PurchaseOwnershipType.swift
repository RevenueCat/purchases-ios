//
//  PurchaseOwnershipType.swift
//  Purchases
//
//  Created by Joshua Liebowitz on 6/24/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCPurchaseOwnershipType) public enum PurchaseOwnershipType: Int {
    /**
     The purchase was made directly by this user.
     */
    case purchased = 0
    /**
     The purchase has been shared to this user by a family member.
     */
    case familyShared = 1

    case unknown = 2
}
