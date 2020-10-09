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
    private let maxJitterInSeconds: Double = 5
    
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

    @objc public func dispatchOnWorkerThread(withRandomDelay: Bool = false,
                                             block: @escaping () -> ()) {
        if withRandomDelay {
            let delay = Double.random(in: 0..<maxJitterInSeconds)
            workerQueue.asyncAfter(deadline: .now() + delay) { block() }
        } else {
            workerQueue.async { block() }
        }
    }
}
