//
//  OperationDispatcher.swift
//  Purchases
//
//  Created by Andrés Boedo on 8/5/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCOperationDispatcher) class OperationDispatcher: NSObject {
    
    private let mainQueue: DispatchQueue
    private let workerQueue: DispatchQueue
    
    override init() {
        mainQueue = DispatchQueue.main
        workerQueue = DispatchQueue(label: "OperationDispatcherWorkerQueue")
    }
    
    @objc func dispatchOnMainThreadIfSet(_ block: (() -> Void)?) {
        if let block = block {
            dispatchOnMainThread {
                block()
            }
        }
    }
    @objc func dispatchOnMainThread(_ block: @escaping(() -> Void)) {
        mainQueue.async { block() }
    }

    @objc func dispatchOnSameThreadIfSet(_ block: () -> Void) {
        block()
    }

    @objc func dispatchOnWorkerThread(_ block: @escaping(() -> Void)) {
        workerQueue.async { block() }
    }

}
