//
//  OperationDispatcher.swift
//  Purchases
//
//  Created by Andrés Boedo on 8/5/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCOperationDispatcher) public class OperationDispatcher: NSObject {
    
    private let mainQueue: DispatchQueue
    private let workerQueue: DispatchQueue
    
    @objc public override init() {
        mainQueue = DispatchQueue.main
        workerQueue = DispatchQueue(label: "OperationDispatcherWorkerQueue")
    }
    
    @objc public func dispatchOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            mainQueue.async { block() }
        }
    }

    @objc public func dispatchOnWorkerThread(_ block: @escaping () -> Void) {
        workerQueue.async { block() }
    }

}
