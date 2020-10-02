//
// Created by Andrés Boedo on 8/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@testable import PurchasesCoreSwift

class MockOperationDispatcher: OperationDispatcher {

    var invokedDispatchOnMainThread = false
    var invokedDispatchOnMainThreadCount = 0
    var shouldInvokeDispatchOnMainThreadBlock = true
    var forwardToOriginalDispatchOnMainThread = false

    override func dispatchOnMainThread(_ block: @escaping () -> Void) {
        invokedDispatchOnMainThread = true
        invokedDispatchOnMainThreadCount += 1
        if forwardToOriginalDispatchOnMainThread {
            super.dispatchOnMainThread(block)
            return
        }
        if shouldInvokeDispatchOnMainThreadBlock {
            block()
        }
    }

    var invokedDispatchOnWorkerThread = false
    var invokedDispatchOnWorkerThreadCount = 0
    var shouldInvokeDispatchOnWorkerThreadBlock = true
    var forwardToOriginalDispatchOnWorkerThread = false

    public override func dispatchOnWorkerThread(withRandomDelay withRandomDelay: BOOL = false,
                                                _ block: @escaping () -> ()) {
        invokedDispatchOnWorkerThread = true
        invokedDispatchOnWorkerThreadCount += 1
        if forwardToOriginalDispatchOnWorkerThread {
            super.dispatchOnWorkerThread(block)
            return
        }
        if shouldInvokeDispatchOnWorkerThreadBlock {
            block()
        }
    }
}
