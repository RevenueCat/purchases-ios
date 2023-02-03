//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionAPI.swift
//
//  Created by Madeline Beyl on 8/26/21.

import Foundation
import RevenueCat

var trans: StoreTransaction!
func checkTransactionAPI() {

    let rci: String = trans.transactionIdentifier
    let pid: String = trans.productIdentifier
    let date: Date = trans.purchaseDate

    print(trans!, rci, pid, date)
}
