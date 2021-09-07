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
        self.periodType = container.decode(PeriodType.self, forKey: .periodType, defaultValue: .normal)
        self.store = container.decode(Store.self, forKey: .store, defaultValue: .unknownStore)
        self.ownershipType = container.decode(PurchaseOwnershipType.self,
                                              forKey: .ownershipType,
                                              defaultValue: .purchased)
    }

}
