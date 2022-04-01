//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OperationDispatcher.swift
//
//  Created by Andrés Boedo on 8/5/20.
//

import Foundation

class OperationDispatcher {

    private let mainQueue = DispatchQueue.main
    private let workerQueue = DispatchQueue(label: "OperationDispatcherWorkerQueue")
    private let maxJitterInSeconds: Double = 5

    static let `default`: OperationDispatcher = .init()

    func dispatchOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            mainQueue.async(execute: block)
        }
    }

    func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping () -> Void) {
        if withRandomDelay {
            let delay = Double.random(in: 0..<maxJitterInSeconds)
            workerQueue.asyncAfter(deadline: .now() + delay, execute: block)
        } else {
            workerQueue.async(execute: block)
        }
    }

}
