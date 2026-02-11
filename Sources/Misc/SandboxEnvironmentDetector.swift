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
/// This attempts to prefetch and parse the local receipt environment.
/// While prefetching (or in case of failure), it falls back to existing non-prefetched checks.
final class SandboxEnvironmentDetector: SandboxEnvironmentDetectorType {

    private let bundle: Atomic<Bundle>
    private let isRunningInSimulator: Bool
    private let receiptFetcher: LocalReceiptFetcherType
    private let macAppStoreDetector: MacAppStoreDetector?

    /// Cached `isSandbox` computed from a prefetched and parsed local receipt.
    /// This is populated asynchronously and used when available.
    private let cachedIsSandboxFromPrefetchedReceipt: Atomic<Bool?> = .init(nil)

    /// Cached result of receipt path-based sandbox detection.
    private let cachedIsSandboxBasedOnReceiptPath: Atomic<Bool?> = .init(nil)

    /// Creates a new detector that prefetches the local receipt environment.
    ///
    /// - Parameters:
    ///   - bundle: The bundle to use for receipt URL detection.
    ///   - isRunningInSimulator: Whether the app is running in a simulator.
    ///   - receiptFetcher: The receipt fetcher for macOS receipt parsing.
    ///   - macAppStoreDetector: Detector for macOS App Store detection.
    ///   - requestFetcher: The request fetcher used to refresh the StoreKit 1 receipt.
    init(
        bundle: Bundle = .main,
        isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator,
        receiptFetcher: LocalReceiptFetcherType = LocalReceiptFetcher(),
        macAppStoreDetector: MacAppStoreDetector? = nil,
        requestFetcher: StoreKitRequestFetcher
    ) {
        self.bundle = .init(bundle)
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptFetcher = receiptFetcher
        self.macAppStoreDetector = macAppStoreDetector

        self.prefetchReceiptEnvironment(requestFetcher: requestFetcher)
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

        // Prefer prefetched receipt environment when available.
        if let cachedIsSandbox = self.cachedIsSandboxFromPrefetchedReceipt.value {
            return cachedIsSandbox
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
    /// prefetched receipt environment detection.
    private static let _default: Atomic<SandboxEnvironmentDetectorType> = .init(SandboxEnvironmentDetector())

    static var `default`: SandboxEnvironmentDetectorType {
        get { _default.value }
        set { _default.value = newValue }
    }

}

// MARK: - Prefetched Receipt Environment Detection

private extension SandboxEnvironmentDetector {

    func prefetchReceiptEnvironment(requestFetcher: StoreKitRequestFetcher) {
        // If there's already a receipt on disk, use it and avoid refreshing.
        guard !self.hasLocalReceiptOnDisk else {
            self.cacheIsSandboxFromLocalReceiptEnvironment()
            return
        }

        requestFetcher.fetchReceiptData {
            self.cacheIsSandboxFromLocalReceiptEnvironment()
        }
    }

    var hasLocalReceiptOnDisk: Bool {
        guard let receiptURL = self.bundle.value.appStoreReceiptURL else {
            return false
        }

        return FileManager.default.fileExists(atPath: receiptURL.path)
    }

    func cacheIsSandboxFromLocalReceiptEnvironment() {
        guard let environment = try? self.receiptFetcher.fetchAndParseLocalReceipt().environment else {
            return
        }

        guard environment != .unknown else {
            return
        }

        self.cachedIsSandboxFromPrefetchedReceipt.value = environment != .production
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
