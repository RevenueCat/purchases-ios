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

/// Represents a delay for asynchonous operations.
///
/// These delays prevent DDOS if a notification leads to many users opening an app at the same time,
/// by spreading asynchronous operations over time.
enum JitterableDelay: Equatable {

    case none
    case `default`
    case long
    case timeInterval(TimeInterval)

    static func `default`(forBackgroundedApp inBackground: Bool) -> Self {
        return inBackground ? .default : .none
    }

}

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

    func dispatchOnWorkerThread(jitterableDelay delay: JitterableDelay = .none, block: @escaping @Sendable () -> Void) {
        if delay.hasDelay {
            self.workerQueue.asyncAfter(deadline: .now() + delay.random(), execute: block)
        } else {
            self.workerQueue.async(execute: block)
        }
    }

    func dispatchOnWorkerThread(jitterableDelay delay: JitterableDelay = .none,
                                block: @escaping @Sendable () async -> Void) {
        Task.detached(priority: .background) {
            if delay.hasDelay {
                try? await Task.sleep(nanoseconds: DispatchTimeInterval(delay.random()).nanoseconds)
            }

            await block()
        }
    }

    func dispatchOnWorkerThread(after timeInterval: TimeInterval, block: @escaping @Sendable () -> Void) {
        self.workerQueue.asyncAfter(deadline: .now() + timeInterval, execute: block)
    }

}

extension OperationDispatcher {

    static func dispatchOnMainActor(_ block: @MainActor @escaping @Sendable () -> Void) {
        Task<Void, Never> { @MainActor in
            block()
        }
    }

}

// MARK: -

/// Visible for testing
extension JitterableDelay {

    var hasDelay: Bool {
        return self.maximum > 0
    }

    var range: Range<TimeInterval> {
        return self.minimum..<self.maximum
    }

}

private extension JitterableDelay {

    var minimum: TimeInterval {
        switch self {
        case .none: return 0
        case .`default`: return 0
        case .long: return Self.maxJitter
        case .timeInterval(let timeInterval):
            return max(timeInterval, 0)
        }
    }

    var maximum: TimeInterval {
        switch self {
        case .none: return 0
        case .`default`: return Self.maxJitter
        case .long: return Self.maxJitter * 2
        case .timeInterval(let timeInterval):
            return max(timeInterval, 0)
        }
    }

    func random() -> TimeInterval {
        Double.random(in: self.range)
    }

    private static let maxJitter: TimeInterval = 5

}

// MARK: -

// `DispatchQueue` is not `Sendable` as of Swift 5.8, but this class performs no mutations.
extension OperationDispatcher: @unchecked Sendable {}
