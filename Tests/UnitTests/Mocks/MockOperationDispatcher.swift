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

    var invokedDispatchAsyncOnMainThread = false
    var invokedDispatchAsyncOnMainThreadCount = 0
    var pendingMainActorDispatches: Atomic<Int> = .init(0)

    override func dispatchAsyncOnMainThread(_ block: @escaping @Sendable () -> Void) {
        self.invokedDispatchAsyncOnMainThread = true
        self.invokedDispatchAsyncOnMainThreadCount += 1

        super.dispatchAsyncOnMainThread(block)
    }

    override func dispatchOnMainActor(_ block: @escaping @Sendable @MainActor () -> Void) {
        let invoke: @Sendable @MainActor () -> Void = { [atomic = self.pendingMainActorDispatches] in
            block()
            atomic.modify { $0 -= 1 }
        }

        self.invokedDispatchOnMainThread = true
        self.invokedDispatchOnMainThreadCount += 1
        self.pendingMainActorDispatches.modify { $0 += 1 }

        if self.forwardToOriginalDispatchOnMainThread {
            super.dispatchOnMainActor(invoke)
        } else {
            OperationDispatcher.dispatchOnMainActor(invoke)
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
