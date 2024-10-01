//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockRequestFetcher: StoreKitRequestFetcher {
    var refreshReceiptCalledCount = 0
    var refreshReceiptCalled = false

    override func fetchReceiptData(_ completion: @MainActor @Sendable @escaping () -> Void) {
        self.refreshReceiptCalledCount += 1
        self.refreshReceiptCalled = true

        OperationDispatcher.dispatchOnMainActor {
            completion()
        }
    }

    convenience init() {
        self.init(operationDispatcher: OperationDispatcher())
    }
}

extension MockRequestFetcher: @unchecked Sendable {}
