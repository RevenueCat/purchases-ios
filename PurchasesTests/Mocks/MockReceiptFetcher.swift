//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockReceiptFetcher: RCReceiptFetcher {
    var receiptDataCalled = false
    var shouldReturnReceipt = true
    var receiptDataTimesCalled = 0

    override func receiptData() -> Data? {
        receiptDataCalled = true
        receiptDataTimesCalled += 1
        if (shouldReturnReceipt) {
            return Data(1...3)
        } else {
            return nil
        }
    }
}