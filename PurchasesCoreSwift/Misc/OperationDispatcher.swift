//
//  OperationDispatcher.swift
//  Purchases
//
//  Created by Andrés Boedo on 8/5/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCOperationDispatcher) public class OperationDispatcher: NSObject {

    private let mainQueue = DispatchQueue.main
    private let workerQueue = DispatchQueue(label: "OperationDispatcherWorkerQueue")
    private let httpQueue = DispatchQueue(label: "HTTPClientQueue")
    private let maxJitterInSeconds: Double = 5

    @objc public func dispatchOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            mainQueue.async(execute: block)
        }
    }

    @objc public func dispatchOnWorkerThread(withRandomDelay: Bool = false,
                                             block: @escaping () -> Void) {
        if withRandomDelay {
            let delay = Double.random(in: 0..<maxJitterInSeconds)
            workerQueue.asyncAfter(deadline: .now() + delay, execute: block)
        } else {
            workerQueue.async(execute: block)
        }
    }

    func dispatchOnHTTPSerialQueue(_ block: @escaping () -> Void) {
        httpQueue.async(execute: block)
    }

}
