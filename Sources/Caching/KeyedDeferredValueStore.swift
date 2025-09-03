//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  KeyedDeferredValueStore.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/25.

import Foundation

/// Some Task in which the value is Sendable and it can result in an error
typealias AnyTask<T: Sendable> = Task<T, Error>

/// Holds onto ``AnyTask`` objects by key, autoclearing on failure
actor KeyedDeferredValueStore<H: Hashable, T: Sendable> {
    var deferred: [H: AnyTask<T>] = [:]

    /// Sets the task in the cache if one is not found
    /// - Parameters:
    ///   - task: The function that should execute if one is not found
    ///   - key: The key to look up the result by
    /// - Returns: The stored task
    func getOrPut(
        _ task: @escaping @Sendable @autoclosure () -> AnyTask<T>,
        forKey key: H
    ) -> AnyTask<T> {
        guard let result = self.deferred[key] else {
            let wrapped: AnyTask<T> = self.forgettingFailure(task, forKey: key)
            self.deferred[key] = wrapped
            return wrapped
        }
        return result
    }

    /// Replaces a task in the store
    /// - Parameter task: The new function to store
    /// - Parameter key: The key to look up the result by
    /// - Returns: The stored task
    func replaceValue(
        _ task: @escaping @Sendable @autoclosure () -> AnyTask<T>,
        forKey key: H
    ) -> AnyTask<T> {
        let result = self.forgettingFailure(task, forKey: key)
        self.deferred[key] = result
        return result
    }

    /// Removes all cached tasks
    func clear() {
        self.deferred = [:]
    }

    private func forgettingFailure(
        _ task: @escaping @Sendable () -> AnyTask<T>,
        forKey key: H
    ) -> AnyTask<T> {
        return Task {
            do {
                return try await task().value
            } catch {
                self.deferred.removeValue(forKey: key)
                throw error
            }
        }
    }

    /// Create a KeyedDeferredValueStore
    init() {}
}
