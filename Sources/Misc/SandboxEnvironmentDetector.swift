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
    private let receiptParser: PurchasesReceiptParser

    init(bundle: Bundle = .main,
         isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator,
         receiptParser: PurchasesReceiptParser = PurchasesReceiptParser.default) {
        self.bundle = .init(bundle)
        self.isRunningInSimulator = isRunningInSimulator
        self.receiptParser = receiptParser
    }

    var isSandbox: Bool {
        guard !self.isRunningInSimulator else {
            return true
        }

        guard let path = self.bundle.value.appStoreReceiptURL?.path else {
            return false
        }

        #if os(macOS) || targetEnvironment(macCatalyst)
            return !self.isProductionReceipt || !Self.isMacAppStore
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

private extension BundleSandboxEnvironmentDetector {

    var isProductionReceipt: Bool {
        do {
            return try receiptFetcher.fetchAndParseLocalReceipt().environment == .production
        } catch {
            Logger.error(Strings.receipt.parse_receipt_locally_error(error: error))
            return false
        }
    }

    /// Returns whether the bundle was signed for Mac App Store distribution by checking
    /// the existence of a specific extension (marker OID) on the code signing certificate.
    ///
    /// This routine is inspired by the source code from ProcInfo, the underlying library
    /// of the WhatsYourSign code signature checking tool developed by Objective-See. Initially,
    /// it checked the common name but was changed to an extension check to make it more
    /// future-proof.
    ///
    /// For more information, see the following references:
    /// - https://github.com/objective-see/ProcInfo/blob/master/procInfo/Signing.m#L184-L247
    /// - https://gist.github.com/lukaskubanek/cbfcab29c0c93e0e9e0a16ab09586996#gistcomment-3993808
    #if os(macOS) || targetEnvironment(macCatalyst)
    static var isMacAppStore: Bool {
        var status = noErr

        var code: SecStaticCode?
        status = SecStaticCodeCreateWithPath(Bundle.main.bundleURL as CFURL, [], &code)

        guard status == noErr, let code = code else {
            Logger.error(Strings.receipt.error_validating_bundle_signature)
            return false
        }

        var requirement: SecRequirement?
        status = SecRequirementCreateWithString(
            "anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.9]" as CFString,
            [], // default
            &requirement
        )

        guard status == noErr, let requirement = requirement else {
            Logger.error(Strings.receipt.error_validating_bundle_signature)
            return false
        }

        status = SecStaticCodeCheckValidity(
            code,
            [], // default
            requirement
        )

        return status == errSecSuccess
    }
    #endif

}
