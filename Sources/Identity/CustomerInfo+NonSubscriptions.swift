//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+NonSubscriptions.swift
//
//  Created by Nacho Soto on 7/18/23.

import Foundation

extension CustomerInfo {

    func containsNonSubscription(_ transation: StoreTransactionType) -> Bool {
        return self.nonSubscriptions.contains {
            $0.transactionIdentifier == transation.transactionIdentifier
        }
    }

}
