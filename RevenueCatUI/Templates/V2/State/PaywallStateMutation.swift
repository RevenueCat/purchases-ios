//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

#if !os(tvOS)

// swiftlint:disable missing_docs

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateMutation: Hashable, Sendable {

    @_spi(Internal) public let key: PaywallStateKey
    @_spi(Internal) public let value: PaywallStateValue?

    @_spi(Internal)
    public init(key: PaywallStateKey, value: PaywallStateValue?) {
        self.key = key
        self.value = value
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateChange: Sendable {

    private init() {}

    @_spi(Internal) public protocol Details: Hashable, Sendable {}
    @_spi(Internal) public protocol Stage: Sendable {}

    @_spi(Internal) public struct Proposed: Stage {
        @_spi(Internal) public init() {}
    }

    @_spi(Internal) public struct Committed: Stage {
        @_spi(Internal) public init() {}
    }

    @_spi(Internal) public struct Event<StageType: Stage>: Sendable {

        @_spi(Internal) public let key: PaywallStateKey
        @_spi(Internal) public let oldValue: PaywallStateValue?
        @_spi(Internal) public let newValue: PaywallStateValue?
        @_spi(Internal) public let details: (any PaywallStateChange.Details)?

        @_spi(Internal)
        public init(
            key: PaywallStateKey,
            oldValue: PaywallStateValue?,
            newValue: PaywallStateValue?,
            details: (any PaywallStateChange.Details)?
        ) {
            self.key = key
            self.oldValue = oldValue
            self.newValue = newValue
            self.details = details
        }

    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateMutationHandler {

    private let action: @Sendable (PaywallStateMutationProposal) -> Void

    @_spi(Internal)
    public init(action: @escaping @Sendable (PaywallStateMutationProposal) -> Void) {
        self.action = action
    }

    func callAsFunction(_ proposal: PaywallStateMutationProposal) {
        self.action(proposal)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public final class PaywallStateMutationProposal: @unchecked Sendable {

    @_spi(Internal) public let change: PaywallStateChange.Event<PaywallStateChange.Proposed>

    private let lock = NSLock()
    private var resolve: ((Resolution) -> Void)?

    init(
        change: PaywallStateChange.Event<PaywallStateChange.Proposed>,
        resolve: @escaping (Resolution) -> Void
    ) {
        self.change = change
        self.resolve = resolve
    }

    deinit {
        #if DEBUG
        assert(self.resolve == nil, "Paywall state mutation proposal was never resolved.")
        #endif
    }

    @_spi(Internal) public func accept() {
        self.handle(.accept)
    }

    @_spi(Internal) public func reject() {
        self.handle(.reject)
    }

    @_spi(Internal) public func replace(with mutation: PaywallStateMutation) {
        self.handle(.replace(mutation))
    }

    private func handle(_ resolution: Resolution) {
        self.lock.lock()
        let callback = self.resolve
        self.resolve = nil
        self.lock.unlock()

        callback?(resolution)
    }

    enum Resolution {
        case accept
        case reject
        case replace(PaywallStateMutation)
    }

}

// swiftlint:enable missing_docs

#endif
