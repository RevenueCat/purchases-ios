//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NetworkOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class CacheableNetworkOperation: NetworkOperation, CacheKeyProviding {

    var cacheKey: String { "\(type(of: self)) \(individualizedCacheKeyPart)" }

    let individualizedCacheKeyPart: String

    /**
     - Parameter individualizedCacheKeyPart: The part of the cacheKey that makes it unique from other operations of the
     same type. Example: If you posted receipts two times in a row you'd have 2 operations. The cache key would be
     PostOperation + individualizedCacheKeyPart where individualizedCacheKeyPart is whatever you determine to be unique.
     */
    init(configuration: NetworkConfiguration, individualizedCacheKeyPart: String) {
        self.individualizedCacheKeyPart = individualizedCacheKeyPart

        super.init(configuration: configuration)
    }

}

class NetworkOperation: Operation {

    let httpClient: HTTPClient

    private var _isExecuting: Atomic<Bool> = false
    private(set) override final var isExecuting: Bool {
        get {
            return self._isExecuting.value
        }
        set {
            self.willChangeValue(for: \.isExecuting)
            self._isExecuting.value = newValue
            self.didChangeValue(for: \.isExecuting)
        }
    }

    private var _isFinished: Atomic<Bool> = false
    private(set) override final var isFinished: Bool {
        get {
            return self._isFinished.value
        }
        set {
            self.willChangeValue(for: \.isFinished)
            self._isFinished.value = newValue
            self.didChangeValue(for: \.isFinished)
        }
    }

    private var _isCancelled: Atomic<Bool> = false
    private(set) override final var isCancelled: Bool {
        get {
            return self._isCancelled.value
        }
        set {
            self.willChangeValue(for: \.isCancelled)
            self._isCancelled.value = newValue
            self.didChangeValue(for: \.isCancelled)
        }
    }

    init(configuration: NetworkConfiguration) {
        self.httpClient = configuration.httpClient

        super.init()
    }

    override final func main() {
        if self.isCancelled {
            self.isFinished = true
            return
        }

        self.isExecuting = true

        self.log("Started")

        self.begin {
            self.finish()
        }
    }

    override final func cancel() {
        self.isCancelled = true
        self.isExecuting = false
        self.isFinished = true

        self.log("Cancelled")
    }

    /// Overriden by subclasses to define the body of the operation
    /// - Important: this method may be called from any thread so it must be thread-safe.
    /// - Parameter completion: must be called when the operation has finished.
    func begin(completion: @escaping () -> Void) {
        fatalError("Subclasses must override this method")
    }

    private final func finish() {
        assert(!self.isFinished, "Operation \(type(of: self)) (\(self)) was already finished")

        self.log("Finished")

        self.isExecuting = false
        self.isFinished = true
    }

    // MARK: -

    final override var isAsynchronous: Bool {
        return true
    }

    // MARK: -

    internal func log(_ message: CustomStringConvertible) {
        Logger.debug("\(type(of: self)): \(message.description)")
    }

    // MARK: -

    struct Configuration: NetworkConfiguration {

        let httpClient: HTTPClient

    }

    struct UserSpecificConfiguration: AppUserConfiguration, NetworkConfiguration {

        let httpClient: HTTPClient
        let appUserID: String

    }

}

protocol AppUserConfiguration {

    var appUserID: String { get }

}

protocol NetworkConfiguration {

    var httpClient: HTTPClient { get }

}
