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

    private let mainQueue: DispatchQueue = .main
    private let workerQueue: DispatchQueue = .init(label: "OperationDispatcherWorkerQueue")
    private let maxJitterInSeconds: Double = 5

    static let `default`: OperationDispatcher = .init()

    func dispatchOnMainThread(_ block: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            self.mainQueue.async(execute: block)
        }
    }

    func dispatchOnMainActor(_ block: @MainActor @escaping @Sendable () -> Void) {
        Self.dispatchOnMainActor(block)
    }

    func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping @Sendable () -> Void) {
        if withRandomDelay {
            let delay = Double.random(in: 0..<self.maxJitterInSeconds)
            self.workerQueue.asyncAfter(deadline: .now() + delay, execute: block)
        } else {
            self.workerQueue.async(execute: block)
        }
    }

}

extension OperationDispatcher {

    static func dispatchOnMainActor(_ block: @MainActor @escaping @Sendable () -> Void) {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            Task<Void, Never> { @MainActor in
                block()
            }
        } else {
            DispatchQueue.main.async { @Sendable in
                block()
            }
        }
    }

}

#if swift(<5.8)
// `DispatchQueue` is not `Sendable` as of Swift 5.7, but this class performs no mutations.
extension OperationDispatcher: @unchecked Sendable {}
#endif
