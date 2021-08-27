//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementData+Extensions.swift
//
//  Created by Juanpe Catalán on 27/8/21.

import Foundation

extension EntitlementInfo.EntitlementData {

    private enum CodingKeys: String, CodingKey {
        case expiresDate, purchaseDate, productIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.productIdentifier = try container.decode(String.self, forKey: .productIdentifier)
        self.expiresDate = try container.decodeIfPresent(Date.self, forKey: .expiresDate)
        self.purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
    }

}
