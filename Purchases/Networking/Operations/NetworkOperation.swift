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
    let authHeaders: [String: String]

    private var _isExecuting: Atomic<Bool> = .init(false)
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

    private var _isFinished: Atomic<Bool> = .init(false)
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

    private var _isCancelled: Atomic<Bool> = .init(false)
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
        self.authHeaders = configuration.authHeaders

        super.init()
    }

    override final func main() {
        if self.isCancelled {
            self.isFinished = true
            return
        }

        self.isExecuting = true

        Self.log("Started")
        self.begin()
    }

    override final func cancel() {
        self.isCancelled = true
        self.isExecuting = false
        self.isFinished = true

        Self.log("Cancelled")
    }

    /// Called by subclasses to complete this operation
    final func finish() {
        assert(!self.isFinished, "Operation \(type(of: self)) (\(self)) was already finished")

        Self.log("Finished")

        self.isExecuting = false
        self.isFinished = true
    }

    /// Overriden by subclasses to define the body of the operation
    func begin() {
        fatalError("Subclasses must override this method")
    }

    // MARK: -

    final override var isAsynchronous: Bool {
        return true
    }

    // MARK: -

    private static func log(_ message: String) {
        Logger.debug("\(type(of: self)): \(message)")
    }

    // MARK: -

    struct Configuration: NetworkConfiguration {

        let httpClient: HTTPClient
        let authHeaders: [String: String]

    }

    struct UserSpecificConfiguration: AppUserConfiguration, NetworkConfiguration {

        let httpClient: HTTPClient
        let authHeaders: [String: String]
        let appUserID: String

    }

}

protocol AppUserConfiguration {

    var appUserID: String { get }

}

protocol NetworkConfiguration {

    var httpClient: HTTPClient { get }
    var authHeaders: [String: String] { get }

}
