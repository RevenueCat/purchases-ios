//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import PurchasesCoreSwift

class MockRequestFetcher: StoreKitRequestFetcher {
    var refreshReceiptCalled = false

    override func fetchReceiptData(_ completion: @escaping () -> Void) {
        refreshReceiptCalled = true
        completion()
    }

    convenience init() {
        self.init(operationDispatcher: OperationDispatcher())
    }
}
