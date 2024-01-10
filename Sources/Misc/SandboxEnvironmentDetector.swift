//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SandboxEnvironmentDetector.swift
//
//  Created by Nacho Soto on 6/2/22.

import Foundation

/// A type that can determine if the current environment is sandbox.
protocol SandboxEnvironmentDetector: Sendable {

    var isSandbox: Bool { get }

}

/// ``SandboxEnvironmentDetector`` that uses a `Bundle` to detect the environment
final class BundleSandboxEnvironmentDetector: SandboxEnvironmentDetector {

    private let bundle: Atomic<Bundle>
    private let isRunningInSimulator: Bool
    private let receiptFetcher: LocalReceiptFetcherType
    private let macAppStoreDetector: MacAppStoreDetector?

    init(
        bundle: Bundle = .main,
        isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator,
        receiptFetcher: LocalReceiptFetcherType = LocalReceiptFetcher(),
        macAppStoreDetector: MacAppStoreDetector? = nil
    ) {
        self.bundle = .init(bundle)
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptFetcher = receiptFetcher
        self.macAppStoreDetector = macAppStoreDetector
    }

    var isSandbox: Bool {
        guard !self.isRunningInSimulator else {
            return true
        }

        guard let path = self.bundle.value.appStoreReceiptURL?.path else {
            return false
        }

        #if os(macOS) || targetEnvironment(macCatalyst)
            return !self.isProductionReceipt || !self.isMacAppStore
        #else
            return path.contains("sandboxReceipt")
        #endif
    }

    #if DEBUG
    // Mutable in tests so it can be overriden
    static var `default`: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    #else
    static let `default`: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    #endif

}

extension BundleSandboxEnvironmentDetector: Sendable {}

// MARK: -

#if os(macOS) || targetEnvironment(macCatalyst)

private extension BundleSandboxEnvironmentDetector {

    var isProductionReceipt: Bool {
        do {
            return try self.receiptFetcher.fetchAndParseLocalReceipt().environment == .production
        } catch {
            Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
            return false
        }
    }

    var isMacAppStore: Bool {
        let detector = self.macAppStoreDetector ?? DefaultMacAppStoreDetector()
        return detector.isMacAppStore
    }

}

#endif
