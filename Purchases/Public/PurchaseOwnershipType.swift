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
