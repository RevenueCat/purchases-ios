//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockRequestFetcher: RCStoreKitRequestFetcher {
    var refreshReceiptCalled = false

    override func fetchReceiptData(_ completion: @escaping RCFetchReceiptCompletionHandler) {
        refreshReceiptCalled = true
        completion()
    }
}
