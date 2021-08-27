//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementProductData+Extensions.swift
//
//  Created by Juanpe Catalán on 27/8/21.

import Foundation

extension EntitlementInfo.ProductData {

    private enum CodingKeys: String, CodingKey {
        case periodType, originalPurchaseDate, expiresDate,
             store, isSandbox, unsubscribeDetectedAt, billingIssuesDetectedAt, ownershipType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.isSandbox = try container.decodeIfPresent(Bool.self, forKey: .isSandbox) ?? false
        self.originalPurchaseDate = try container.decodeIfPresent(Date.self, forKey: .originalPurchaseDate)
        self.expiresDate = try container.decodeIfPresent(Date.self, forKey: .expiresDate)
        self.unsubscribeDetectedAt = try container.decodeIfPresent(Date.self, forKey: .unsubscribeDetectedAt)
        self.billingIssuesDetectedAt = try container.decodeIfPresent(Date.self, forKey: .billingIssuesDetectedAt)

        if let periodType = try container.decodeIfPresent(PeriodType.self, forKey: .periodType) {
            self.periodType = periodType
        } else {
            Logger.warn("nil periodType found during decoding")
            self.periodType = .normal
        }

        if let ownershipType = try container.decodeIfPresent(PurchaseOwnershipType.self, forKey: .ownershipType) {
            self.ownershipType = ownershipType
        } else {
            Logger.warn("nil ownershipType found during decoding")
            self.ownershipType = .purchased
        }

        if let store = try container.decodeIfPresent(Store.self, forKey: .store) {
            self.store = store
        } else {
            Logger.warn("nil store found during decoding")
            self.store = .unknownStore
        }
    }

}
