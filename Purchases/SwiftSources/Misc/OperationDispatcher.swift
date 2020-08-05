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
            dispatch(onMainThread: {
                block()
            })
        }
    }
    
    @objc func dispatch(onMainThread block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            mainQueue.async { block() }
        }
    }

    @objc func dispatchOnSameThreadIfSet(_ block: () -> Void) {
        block()
    }

    @objc func dispatch(onWorkerThread block: @escaping () -> Void) {
        workerQueue.async { block() }
    }

}
