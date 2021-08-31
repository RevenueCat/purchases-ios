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
import Purchases

func checkTransactionAPI() {
    let trans = Transaction.init(transactionId: "", productId: "", purchaseDate: Date())
    let rci: String = trans.revenueCatId
    let pid: String = trans.productId
    let date: Date = trans.purchaseDate

    print(trans, rci, pid, date)
}
