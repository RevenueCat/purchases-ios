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
    var invokedDispatchOnWorkerThreadDelayParam: Delay?

    override func dispatchOnWorkerThread(delay: Delay = .none, block: @escaping @Sendable () -> Void) {
        self.invokedDispatchOnWorkerThreadDelayParam = delay
        self.invokedDispatchOnWorkerThread = true
        self.invokedDispatchOnWorkerThreadCount += 1
        if self.forwardToOriginalDispatchOnWorkerThread {
            super.dispatchOnWorkerThread(delay: delay, block: block)
            return
        }
        if self.shouldInvokeDispatchOnWorkerThreadBlock {
            block()
        }
    }

    var invokedDispatchAsyncOnWorkerThread = false
    var invokedDispatchAsyncOnWorkerThreadCount = 0
    var invokedDispatchAsyncOnWorkerThreadDelayParam: Delay?

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    override func dispatchOnWorkerThread(
        delay: Delay = .none,
        block: @escaping @Sendable () async -> Void
    ) {
        self.invokedDispatchAsyncOnWorkerThreadDelayParam = delay
        self.invokedDispatchAsyncOnWorkerThread = true
        self.invokedDispatchAsyncOnWorkerThreadCount += 1

        if self.forwardToOriginalDispatchOnWorkerThread {
            super.dispatchOnWorkerThread(delay: delay, block: block)
        } else if self.shouldInvokeDispatchOnWorkerThreadBlock {
            Task<Void, Never> {
                await block()
            }
        }
    }

}
