//
// Created by Andrés Boedo on 8/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@testable import RevenueCat

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
    var invokedDispatchOnWorkerThreadRandomDelayParam: Bool?

    public override func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping () -> Void) {
        invokedDispatchOnWorkerThreadRandomDelayParam = withRandomDelay
        invokedDispatchOnWorkerThread = true
        invokedDispatchOnWorkerThreadCount += 1
        if forwardToOriginalDispatchOnWorkerThread {
            super.dispatchOnWorkerThread(withRandomDelay: withRandomDelay, block: block)
            return
        }
        if shouldInvokeDispatchOnWorkerThreadBlock {
            block()
        }
    }
}
