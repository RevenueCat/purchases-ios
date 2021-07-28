//
// Created by Andrés Boedo on 8/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@testable import PurchasesCoreSwift

class MockOperationDispatcher: OperationDispatcher {

    let serialQueue = DispatchQueue(label: "MockOperationDispatcher Serial Queue")

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
    var invokedDispatchOnWorkerThreadRandomDelayParam: Bool? = nil

    public override func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping () -> ()) {
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
    
    var invokedDispatchOnHTTPSerialQueue = false
    var invokedDispatchOnHTTPSerialQueueCount = 0
    var shouldInvokeDispatchOnHTTPSerialQueueBlock = true
    var forwardToOriginalDispatchOnHTTPSerialQueue = false

    override func dispatchOnHTTPSerialQueue(_ block: @escaping () -> Void) {
        invokedDispatchOnHTTPSerialQueue = true
        invokedDispatchOnHTTPSerialQueueCount += 1
        if forwardToOriginalDispatchOnHTTPSerialQueue {
            super.dispatchOnHTTPSerialQueue(block)
            return
        }
        if shouldInvokeDispatchOnHTTPSerialQueueBlock {
            serialQueue.async(execute: block)
        }
    }
}
