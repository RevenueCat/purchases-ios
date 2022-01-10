//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTransactionsManager.swift
//
//  Created by Juanpe Catalán on 10/12/21.

import Foundation
@testable import RevenueCat

class MockTransactionsManager: TransactionsManager {

    var invokedCustomerHasTransactions = false
    var invokedCustomerHasTransactionsCount = 0
    var invokedCustomerHasTransactionsParameters: Data?
    var invokedCustomerHasTransactionsParametersList = [Data]()
    var stubbedCustomerHasTransactionsCompletionParameter = false

    override func customerHasTransactions(receiptData: Data, completion: @escaping (Bool) -> Void) {
        invokedCustomerHasTransactions = true
        invokedCustomerHasTransactionsCount += 1
        invokedCustomerHasTransactionsParameters = receiptData
        invokedCustomerHasTransactionsParametersList.append(receiptData)
        completion(stubbedCustomerHasTransactionsCompletionParameter)
    }

}
