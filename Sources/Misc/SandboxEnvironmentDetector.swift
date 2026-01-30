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

    /// Cached environment from `AppTransaction` (iOS 16+).
    /// This is populated asynchronously and used for more reliable sandbox detection.
    private let cachedAppTransactionEnvironment: Atomic<StoreEnvironment?> = .init(nil)

    /// Cached result of receipt path-based sandbox detection.
    private let cachedIsSandboxBasedOnReceiptPath: Atomic<Bool?> = .init(nil)

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
        self.bundle = .init(bundle)
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptFetcher = receiptFetcher
        self.macAppStoreDetector = macAppStoreDetector

        // Start fetching the AppTransaction environment asynchronously.
        // The result will be cached and used by `isSandbox` once available.
        self.prefetchAppTransactionEnvironmentIfAvailable(transactionFetcher: transactionFetcher)
    }

    private init() {
        self.bundle = .init(Bundle.main)
        self.isRunningInSimulator = SystemInfo.isRunningInSimulator
        self.receiptFetcher = LocalReceiptFetcher()
        self.macAppStoreDetector = nil
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

    // MARK: - Default Instance

    /// The default sandbox environment detector.
    ///
    /// By default, this uses a simplified `SandboxEnvironmentDetector` that only relies on
    /// the legacy receipt path detection. When the SDK is initialized via `Purchases.configure()`,
    /// this is replaced with a full `SandboxEnvironmentDetector` that includes
    /// `AppTransaction`-based detection on iOS 16+.
    private static let _default: Atomic<SandboxEnvironmentDetectorType> = .init(SandboxEnvironmentDetector())

    static var `default`: SandboxEnvironmentDetectorType {
        get { _default.value }
        set { _default.value = newValue }
    }

}

// MARK: - AppTransaction Environment Detection (iOS 16+)

private extension SandboxEnvironmentDetector {

    func prefetchAppTransactionEnvironmentIfAvailable(transactionFetcher: StoreKit2TransactionFetcherType) {
        Task.detached {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                try! await Task.sleep(for: .seconds(20))
                self.cachedAppTransactionEnvironment.value = .sandbox
            }
        }
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
