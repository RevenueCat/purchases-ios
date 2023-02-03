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

    override func dispatchOnMainThread(_ block: @escaping @Sendable () -> Void) {
        self.invokedDispatchOnMainThread = true
        self.invokedDispatchOnMainThreadCount += 1

        if self.forwardToOriginalDispatchOnMainThread {
            super.dispatchOnMainThread(block)
        } else if self.shouldInvokeDispatchOnMainThreadBlock {
            block()
        }
    }

    override func dispatchOnMainActor(_ block: @escaping @Sendable @MainActor () -> Void) {
        self.invokedDispatchOnMainThread = true
        self.invokedDispatchOnMainThreadCount += 1

        if self.forwardToOriginalDispatchOnMainThread {
            super.dispatchOnMainActor(block)
        } else {
            OperationDispatcher.dispatchOnMainActor {
                block()
            }
        }
    }

    var invokedDispatchOnWorkerThread = false
    var invokedDispatchOnWorkerThreadCount = 0
    var shouldInvokeDispatchOnWorkerThreadBlock = true
    var forwardToOriginalDispatchOnWorkerThread = false
    var invokedDispatchOnWorkerThreadRandomDelayParam: Bool?

    public override func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping @Sendable () -> Void) {
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
