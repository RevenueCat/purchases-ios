//
// Created by Andrés Boedo on 8/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import PurchasesCoreSwift

class MockReceiptParser: ReceiptParser {
    
    init() {
        super.init(objectIdentifierBuilder: ASN1ObjectIdentifierBuilder(),
                   containerBuilder: ASN1ContainerBuilder(),
                   receiptBuilder: AppleReceiptBuilder())
    }

    var invokedReceiptHasTransactions = false
    var invokedReceiptHasTransactionsCount = 0
    var invokedReceiptHasTransactionsParameters: (receiptData: Data, Void)?
    var invokedReceiptHasTransactionsParametersList = [(receiptData: Data, Void)]()
    var stubbedReceiptHasTransactionsResult: Bool! = false

    override func receiptHasTransactions(receiptData: Data) -> Bool {
        invokedReceiptHasTransactions = true
        invokedReceiptHasTransactionsCount += 1
        invokedReceiptHasTransactionsParameters = (receiptData, ())
        invokedReceiptHasTransactionsParametersList.append((receiptData, ()))
        return stubbedReceiptHasTransactionsResult
    }
}
