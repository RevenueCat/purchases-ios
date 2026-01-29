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
///
/// On iOS 16+, this attempts to use `AppTransaction.environment` for more reliable detection.
/// On older OS versions (and in case of failure to retrieve), it falls back to checking the receipt file path.
final class BundleSandboxEnvironmentDetector: SandboxEnvironmentDetector {

    private let bundle: Bundle
    private let isRunningInSimulator: Bool
    private let receiptFetcher: LocalReceiptFetcherType
    private let macAppStoreDetector: MacAppStoreDetector?

    /// Cached environment from `AppTransaction` (iOS 16+).
    /// This is populated asynchronously and used for more reliable sandbox detection.
    private let cachedAppTransactionEnvironment: Atomic<StoreEnvironment?>

    /// Creates a new detector that uses `AppTransaction` for environment detection on iOS 16+.
    ///
    /// - Parameters:
    ///   - bundle: The bundle to use for receipt URL detection.
    ///   - isRunningInSimulator: Whether the app is running in a simulator.
    ///   - receiptFetcher: The receipt fetcher for macOS receipt parsing.
    ///   - macAppStoreDetector: Detector for macOS App Store detection.
    ///   - transactionFetcher: The transaction fetcher used to get `AppTransaction` environment.
    init(
        bundle: Bundle = .main,
        isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator,
        receiptFetcher: LocalReceiptFetcherType = LocalReceiptFetcher(),
        macAppStoreDetector: MacAppStoreDetector? = nil,
        transactionFetcher: StoreKit2TransactionFetcherType
    ) {
        self.bundle = bundle
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptFetcher = receiptFetcher
        self.macAppStoreDetector = macAppStoreDetector
        self.cachedAppTransactionEnvironment = .init(nil)

        // Start fetching the AppTransaction environment asynchronously.
        // The result will be cached and used by `isSandbox` once available.
        self.prefetchAppTransactionEnvironmentIfAvailable(transactionFetcher: transactionFetcher)
    }

    private init() {
        self.bundle = Bundle.main
        self.isRunningInSimulator = SystemInfo.isRunningInSimulator
        self.receiptFetcher = LocalReceiptFetcher()
        self.macAppStoreDetector = nil
        self.cachedAppTransactionEnvironment = .init(nil)
    }

    #if DEBUG
    /// Initializer for testing that allows injecting a pre-cached environment.
    init(
        bundle: Bundle = .main,
        isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator,
        receiptFetcher: LocalReceiptFetcherType = LocalReceiptFetcher(),
        macAppStoreDetector: MacAppStoreDetector? = nil,
        cachedAppTransactionEnvironment: StoreEnvironment?
    ) {
        self.bundle = bundle
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptFetcher = receiptFetcher
        self.macAppStoreDetector = macAppStoreDetector
        self.cachedAppTransactionEnvironment = .init(cachedAppTransactionEnvironment)
    }
    #endif

    var isSandbox: Bool {
        guard !self.isRunningInSimulator else {
            return true
        }

        // On iOS 16+, prefer the cached AppTransaction environment if available.
        // This is more reliable than the receipt path-based detection.
        if let cachedEnvironment = self.cachedAppTransactionEnvironment.value {
            return cachedEnvironment != .production
        }

        // Fallback to the legacy path-based detection.
        return self.isSandboxBasedOnReceiptPath
    }

    // MARK: - Default Instance

    /// The default sandbox environment detector.
    ///
    /// By default, this uses the `FallbackSandboxEnvironmentDetector` which relies on
    /// the legacy receipt path detection. When the SDK is initialized via `Purchases.configure()`,
    /// this is replaced with a full `BundleSandboxEnvironmentDetector` that includes
    /// `AppTransaction`-based detection on iOS 16+.
    private static let _default: Atomic<SandboxEnvironmentDetector> = .init(BundleSandboxEnvironmentDetector())

    static var `default`: SandboxEnvironmentDetector {
        get { _default.value }
        set { _default.value = newValue }
    }

}

// MARK: - AppTransaction Environment Detection (iOS 16+)

private extension BundleSandboxEnvironmentDetector {

    func prefetchAppTransactionEnvironmentIfAvailable(transactionFetcher: StoreKit2TransactionFetcherType) {
        Task {
            let environment = await transactionFetcher.appTransactionEnvironment
            self.cachedAppTransactionEnvironment.value = environment
        }
    }

}

// MARK: - Legacy Receipt Path-Based Detection

private extension BundleSandboxEnvironmentDetector {

    var isSandboxBasedOnReceiptPath: Bool {
        guard let path = self.bundle.appStoreReceiptURL?.path else {
            return false
        }

        #if os(macOS) || targetEnvironment(macCatalyst)
        // this relies on an undocumented field in the receipt that provides the Environment.
        // if it's not present, we go to a secondary check.
        if let isProductionReceipt = self.isProductionReceipt {
            return !isProductionReceipt
        } else {
            return !self.isMacAppStore
        }

        #else
            return path.contains("sandboxReceipt")
        #endif
    }

}

extension BundleSandboxEnvironmentDetector: Sendable {}

// MARK: -

#if os(macOS) || targetEnvironment(macCatalyst)

private extension BundleSandboxEnvironmentDetector {

    var isProductionReceipt: Bool? {
        do {
            let receiptEnvironment = try self.receiptFetcher.fetchAndParseLocalReceipt().environment
            guard receiptEnvironment != .unknown else { return nil } // don't make assumptions if we're not sure
            return receiptEnvironment == .production
        } catch {
            Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
            return nil
        }
    }

    var isMacAppStore: Bool {
        let detector = self.macAppStoreDetector ?? DefaultMacAppStoreDetector()
        return detector.isMacAppStore
    }

}

#endif
