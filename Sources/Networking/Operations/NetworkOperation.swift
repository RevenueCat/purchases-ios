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

/// A type that can construct a `CacheableNetworkOperation` and pre-compute a cache key.
final class CacheableNetworkOperationFactory<T: CacheableNetworkOperation> {

    let creator: (_ cacheKey: String) -> T
    let cacheKey: String
    var operationType: T.Type { T.self }

    /**
     - Parameter individualizedCacheKeyPart: The part of the cacheKey that makes it unique from other operations of the
     same type. Example: If you posted receipts two times in a row you'd have 2 operations. The cache key would be
     PostOperation + individualizedCacheKeyPart where individualizedCacheKeyPart is whatever you determine to be unique.
     */
    init(_ creator: @escaping (_ cacheKey: String) -> T, individualizedCacheKeyPart: String) {
        self.creator = creator
        self.cacheKey = T.cacheKey(with: individualizedCacheKeyPart)
    }

    func create() -> T {
        return self.creator(self.cacheKey)
    }

}

class CacheableNetworkOperation: NetworkOperation, CacheKeyProviding {

    let cacheKey: String

    init(configuration: NetworkConfiguration, cacheKey: String) {
        self.cacheKey = cacheKey

        super.init(configuration: configuration)
    }

    fileprivate static func cacheKey(with individualizedCacheKeyPart: String) -> String {
        return "\(Self.self) \(individualizedCacheKeyPart)"
    }

}

class NetworkOperation: Operation {

    let httpClient: HTTPClient

    private let _didStart: Atomic<Bool> = false
    private var didStart: Bool { return self._didStart.value }

    // Note: implementing asynchronousy `Operations` needs KVO.
    // We're not using Swift's `KeyPath` verison (`willChangeValue(for:)`)
    // due to it crashing on iOS 12. See https://github.com/RevenueCat/purchases-ios/pull/2008.

    private let _isExecuting: Atomic<Bool> = false
    private(set) override final var isExecuting: Bool {
        get {
            return self._isExecuting.value
        }
        set {
            self.willChangeValue(forKey: #keyPath(NetworkOperation.isExecuting))
            self._isExecuting.value = newValue
            self.didChangeValue(forKey: #keyPath(NetworkOperation.isExecuting))
        }
    }

    private let _isFinished: Atomic<Bool> = false
    private(set) override final var isFinished: Bool {
        get {
            return self._isFinished.value
        }
        set {
            self.willChangeValue(forKey: #keyPath(NetworkOperation.isFinished))
            self._isFinished.value = newValue
            self.didChangeValue(forKey: #keyPath(NetworkOperation.isFinished))
        }
    }

    private let _isCancelled: Atomic<Bool> = false
    private(set) override final var isCancelled: Bool {
        get {
            return self._isCancelled.value
        }
        set {
            self.willChangeValue(forKey: #keyPath(NetworkOperation.isCancelled))
            self._isCancelled.value = newValue
            self.didChangeValue(forKey: #keyPath(NetworkOperation.isCancelled))

        }
    }

    init(configuration: NetworkConfiguration) {
        self.httpClient = configuration.httpClient

        super.init()
    }

    deinit {
        #if DEBUG
        if ProcessInfo.isRunningRevenueCatTests {
            precondition(
                self.didStart,
                "\(type(of: self)) was deallocated but it never started. Did it need to be created?"
            )
            precondition(
                self.isFinished,
                "\(type(of: self)) started but never finished. " +
                "Did the operation not call `completion` in its `begin` implementation?"
            )
        }
        #endif
    }

    override final func main() {
        self._didStart.value = true

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
