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
import StoreKit

/// A type that can determine if the current environment is sandbox.
protocol SandboxEnvironmentDetectorType: Sendable {

    var isSandbox: Bool { get }

    func cancelInFlightAppTransactionPrefetch()
}

/// Object used to detect the sandbox environment
///
/// On iOS 16+, this attempts to use `AppTransaction.environment` for more reliable detection.
/// On older OS versions (and in case of failure to retrieve), it falls back to checking the receipt file path.
final class SandboxEnvironmentDetector: SandboxEnvironmentDetectorType {

    private let bundle: Atomic<Bundle>
    private let isRunningInSimulator: Bool
    private let receiptFetcher: LocalReceiptFetcherType
    private let macAppStoreDetector: MacAppStoreDetector?

    private let appTransactionFetchTask: Atomic<Task<Void, Never>?>

    /// Cached environment from `AppTransaction` (iOS 16+).
    /// This is populated asynchronously and used for more reliable sandbox detection.
    private let cachedAppTransactionEnvironment: Atomic<StoreEnvironment?> = .init(nil)

    /// Cached result of receipt path-based sandbox detection.
    private let cachedIsSandboxBasedOnReceiptPath: Atomic<Bool?> = .init(nil)

    /// Creates a new detector that uses `AppTransaction` for environment detection on iOS 18+.
    ///
    /// - Parameters:
    ///   - bundle: The bundle to use for receipt URL detection.
    ///   - isRunningInSimulator: Whether the app is running in a simulator.
    ///   - receiptFetcher: The receipt fetcher for macOS receipt parsing.
    ///   - macAppStoreDetector: Detector for macOS App Store detection.
    ///   - transactionFetcher: The transaction fetcher used to get `AppTransaction` environment.
    ///     If `nil`, only receipt-path-based detection is used.
    init(
        bundle: Bundle = .main,
        isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator,
        receiptFetcher: LocalReceiptFetcherType = LocalReceiptFetcher(),
        macAppStoreDetector: MacAppStoreDetector? = nil,
        transactionFetcher: StoreKit2TransactionFetcherType? = nil
    ) {
        self.bundle = .init(bundle)
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptFetcher = receiptFetcher
        self.macAppStoreDetector = macAppStoreDetector
        self.appTransactionFetchTask = Atomic(nil)

        if let transactionFetcher,
           #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            // Start fetching the AppTransaction environment asynchronously.
            // The result will be cached and used by `isSandbox` once available.
            self.prefetchAppTransactionEnvironmentIfAvailable(transactionFetcher: transactionFetcher)
        }
    }

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
        if let cachedIsSandbox = self.cachedIsSandboxBasedOnReceiptPath.value {
            return cachedIsSandbox
        }

        // Cache the result to avoid recomputing it
        let isSandboxBasedOnReceiptPath = self.getIsSandboxBasedOnReceiptPath()
        self.cachedIsSandboxBasedOnReceiptPath.value = isSandboxBasedOnReceiptPath
        return isSandboxBasedOnReceiptPath
    }

}

// MARK: - AppTransaction Environment Detection (iOS 16+)

internal extension SandboxEnvironmentDetector {

    // This is only used on iOS 18+ because we observed that on iOS 16/17,
    // prefetching the AppTransaction would sometimes cause the StoreKit daemon to freeze
    // while running automated tests in some environments, which doesn't occur on iOS 18+.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func prefetchAppTransactionEnvironmentIfAvailable(transactionFetcher: StoreKit2TransactionFetcherType) {
        guard self.appTransactionFetchTask.value == nil else {
            // Prefetch is already in progress, don't prefetch again
            return
        }

        // Important: Do not use background priority on this task.
        // In testing, this caused `AppTransaction.shared` to sometimes
        // throw a cancellation error despite no explicit cancellation.
        self.appTransactionFetchTask.value = Task {
            let environment = await transactionFetcher.appTransactionEnvironment
            self.cachedAppTransactionEnvironment.value = environment
            self.appTransactionFetchTask.value = nil
        }
    }

    func cancelInFlightAppTransactionPrefetch() {
        self.appTransactionFetchTask.value?.cancel()
        self.appTransactionFetchTask.value = nil
    }
}

// MARK: - Legacy Receipt Path-Based Detection

private extension SandboxEnvironmentDetector {

    func getIsSandboxBasedOnReceiptPath() -> Bool {
        guard let path = self.bundle.value.appStoreReceiptURL?.path else {
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

extension SandboxEnvironmentDetector: Sendable {}

// MARK: -

#if os(macOS) || targetEnvironment(macCatalyst)

private extension SandboxEnvironmentDetector {

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
