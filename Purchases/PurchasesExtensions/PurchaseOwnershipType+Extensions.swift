//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseOwnershipType+Extensions.swift
//
//  Created by Juanpe Catalán on 26/8/21.

import Foundation

extension PurchaseOwnershipType: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let purchaseOwnershipTypeString = try container.decode(String.self)

        switch purchaseOwnershipTypeString {
        case "PURCHASED":
            self = .purchased
        case "FAMILY_SHARED":
            self = .familyShared
        default:
            Logger.warn("received unknown ownershipType: \(purchaseOwnershipTypeString)")
            self = .unknown
        }
    }

}
