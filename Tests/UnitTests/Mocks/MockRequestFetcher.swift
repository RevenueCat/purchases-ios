//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockRequestFetcher: StoreKitRequestFetcher {
    var refreshReceiptCalled = false

    override func fetchReceiptData(_ completion: @MainActor @Sendable @escaping () -> Void) {
        refreshReceiptCalled = true
        OperationDispatcher.dispatchOnMainActor {
            completion()
        }
    }

    convenience init() {
        self.init(operationDispatcher: OperationDispatcher())
    }
}
