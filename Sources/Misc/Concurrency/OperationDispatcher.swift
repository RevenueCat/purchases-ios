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

    static let `default`: OperationDispatcher = .init()

    /// Invokes `block` on the main thread asynchronously
    /// or synchronously if called from the main thread.
    func dispatchOnMainThread(_ block: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            self.mainQueue.async(execute: block)
        }
    }

    /// Dispatch block on main thread asynchronously.
    func dispatchAsyncOnMainThread(_ block: @escaping @Sendable () -> Void) {
        self.mainQueue.async(execute: block)
    }

    func dispatchOnMainActor(_ block: @MainActor @escaping @Sendable () -> Void) {
        Self.dispatchOnMainActor(block)
    }

    func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping @Sendable () -> Void) {
        if withRandomDelay {
            self.workerQueue.asyncAfter(deadline: .now() + Self.randomDelay(), execute: block)
        } else {
            self.workerQueue.async(execute: block)
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func dispatchOnWorkerThread(withRandomDelay: Bool = false, block: @escaping @Sendable () async -> Void) {
        Task.detached(priority: .background) {
            if withRandomDelay {
                try? await Task.sleep(nanoseconds: DispatchTimeInterval(Self.randomDelay()).nanoseconds)
            }

            await block()
        }
    }

    /// Prevent DDOS if a notification leads to many users opening an app at the same time,
    /// by spreading asynchronous operations over time.
    private static func randomDelay() -> TimeInterval {
        Double.random(in: 0..<Self.maxJitterInSeconds)
    }

    private static let maxJitterInSeconds: Double = 5

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

// `DispatchQueue` is not `Sendable` as of Swift 5.8, but this class performs no mutations.
extension OperationDispatcher: @unchecked Sendable {}
